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

# Prerequisuite

sudo apt-get update
sudo apt-get install unzip wget python-pip -y
pip install --upgrade pip
pip install ansible==2.7.10
wget -O packer.zip https://releases.hashicorp.com/packer/1.3.1/packer_1.3.1_linux_amd64.zip
unzip -o packer.zip
sudo apt-get update
sudo apt-get install qemu-utils -y
pip install python-swiftclient==3.6.0 python-openstackclient==3.17.0

# Check integrity of ovftool

OVFTOOL_MD5=$(docker run -it moander/ovftool md5sum /usr/local/bin/ovftool | cut -d ' ' -f 1)
if [ "$OVFTOOL_MD5" != "e521b64686d65de9e91288225b38d5da" ]; then
  echo ovftool md5 mismatch ... exiting
  exit 1
fi

# Create image on glance and save on disk
# source cicd/get_latest_kubespray_minor.sh
# KUBESPRAY_VERSION=$(get_latest_kubespray_minor $1)
# export KUBESPRAY_VERSION
# echo The kubespray version used will be ${KUBESPRAY_VERSION}
# KUBERNETES_VERSION=$(curl -sS https://raw.githubusercontent.com/kubernetes-sigs/kubespray/$KUBESPRAY_VERSION/inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml | grep kube_version | cut -d ' ' -f 2)
KUBERNETES_VERSION="1.15.3"
IMAGE_NAME=kubernetes-$KUBERNETES_VERSION-$TRAVIS_BUILD_NUMBER
export IMAGE_NAME
./packer build packer.json
openstack image save $IMAGE_NAME --file $IMAGE_NAME.qcow2

# Create container
openstack container create automium-catalog-images
swift post automium-catalog-images --read-acl ".r:*,.rlistings"

# Upload image for openstack to swift
mkdir openstack
ln $IMAGE_NAME.qcow2 openstack/$IMAGE_NAME.qcow2
swift upload automium-catalog-images openstack/$IMAGE_NAME.qcow2 &

# Create ova
qemu-img convert -f qcow2 -O vmdk $IMAGE_NAME.qcow2 automium-dummy.vmdk
docker run --rm -it -v $(pwd):/root moander/ovftool ovftool /root/dummy.vmx /root/$IMAGE_NAME.ova
sudo chmod o+r $IMAGE_NAME.ova

# Upload image for vsphere to swift
mkdir vsphere
mv $IMAGE_NAME.ova vsphere/$IMAGE_NAME.ova
swift upload automium-catalog-images vsphere/$IMAGE_NAME.ova &

# Wait vsphere image upload
wait %2

# Upload image for vcd to swift (link to vsphere)
touch temp && swift upload automium-catalog-images --object-name vcd/$IMAGE_NAME.ova -H "X-Object-Manifest: automium-catalog-images/vsphere/$IMAGE_NAME.ova" temp

# Wait openstack image upload
wait %3

# Make the release
until curl -f https://api.github.com/repos/automium/service-kubernetes/releases?access_token=$GITHUB_TOKEN \
  -X POST -d "{ \"tag_name\": \"$IMAGE_NAME\", \"target_commitish\": \"$TRAVIS_COMMIT\", \"name\": \"$IMAGE_NAME\", \"body\": \"\", \"draft\": false, \"prerelease\": false }"; do sleep 10; done
