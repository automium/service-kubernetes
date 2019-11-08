#!/bin/bash

set -e
set -x

function keep_alive() {
  while true; do
    echo -en "\a"
    sleep 300
  done
}
keep_alive &

# Extract and check integrity of ovftool
docker create --name=ovftool-container moander/ovftool
docker cp ovftool-container:/usr/local/lib/vmware-ovftool /usr/local/lib/
docker rm ovftool-container

OVFTOOL_MD5=$(md5sum /usr/local/lib/vmware-ovftool/ovftool | cut -d ' ' -f 1)
if [ "$OVFTOOL_MD5" != "e521b64686d65de9e91288225b38d5da" ]; then
   echo "ovftool md5 mismatch, aborting build"
   exit 1
fi

# Create image on glance and save on disk
# source cicd/get_latest_kubespray_minor.sh
# KUBESPRAY_VERSION=$(get_latest_kubespray_minor $1)
# export KUBESPRAY_VERSION
# echo The kubespray version used will be ${KUBESPRAY_VERSION}
# KUBERNETES_VERSION=$(curl -sS https://raw.githubusercontent.com/kubernetes-sigs/kubespray/$KUBESPRAY_VERSION/inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml | grep kube_version | cut -d ' ' -f 2)
KUBERNETES_VERSION="1.15.3"
IMAGE_NAME=kubernetes-$KUBERNETES_VERSION-$CI_COMMIT_SHORT_SHA
export IMAGE_NAME
packer build packer.json
sleep 10
openstack image save $IMAGE_NAME --file $IMAGE_NAME.qcow2

# Create container
openstack container create automium-catalog-images
swift post automium-catalog-images --read-acl ".r:*,.rlistings"

# Upload image for openstack to swift
mkdir openstack
ln $IMAGE_NAME.qcow2 openstack/$IMAGE_NAME.qcow2
swift upload automium-catalog-images openstack/$IMAGE_NAME.qcow2 &

# Create ova
mkdir vsphere
qemu-img convert -f qcow2 -O vmdk $IMAGE_NAME.qcow2 automium-dummy.vmdk
/usr/local/lib/vmware-ovftool/ovftool dummy.vmx vsphere/$IMAGE_NAME.ova
chmod o+r vsphere/$IMAGE_NAME.ova

# Upload image for vsphere to swift
swift upload automium-catalog-images vsphere/$IMAGE_NAME.ova &

# Wait vsphere image upload
wait %2

# Upload image for vcd to swift (link to vsphere)
touch temp && swift upload automium-catalog-images --object-name vcd/$IMAGE_NAME.ova -H "X-Object-Manifest: automium-catalog-images/vsphere/$IMAGE_NAME.ova" temp

# Wait openstack image upload
wait %3

echo "Done"

# Make the release
# until curl -f https://api.github.com/repos/automium/service-kubernetes/releases?access_token=$GITHUB_TOKEN \
#   -X POST -d "{ \"tag_name\": \"$IMAGE_NAME\", \"target_commitish\": \"$TRAVIS_COMMIT\", \"name\": \"$IMAGE_NAME\", \"body\": \"\", \"draft\": false, \"prerelease\": false }"; do sleep 10; done
