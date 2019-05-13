#!/bin/bash

set -e
set -x

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

# Create images

KUBESPRAY_VERSION=$(grep kubespray_version defaults/main.yml | cut -d ' ' -f 2)
KUBERNETES_VERSION=$(curl -sS https://raw.githubusercontent.com/kubernetes-sigs/kubespray/$KUBESPRAY_VERSION/inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml | grep kube_version | cut -d ' ' -f 2)
IMAGE_NAME=kubernetes-$KUBERNETES_VERSION-$TRAVIS_BUILD_NUMBER
export IMAGE_NAME
./packer build packer.json
openstack image save $IMAGE_NAME --file $IMAGE_NAME.qcow2
qemu-img convert -f qcow2 -O vmdk $IMAGE_NAME.qcow2 automium-dummy.vmdk
docker run --rm -it -v $(pwd):/root moander/ovftool ovftool /root/dummy.vmx /root/$IMAGE_NAME.ova
sudo chmod o+r $IMAGE_NAME.ova
mkdir vsphere
mv $IMAGE_NAME.ova vsphere/$IMAGE_NAME.ova
openstack container create automium-catalog-images
swift post automium-catalog-images --read-acl ".r:*,.rlistings"
# Upload image for vsphere to swift
openstack object create automium-catalog-images vsphere/$IMAGE_NAME.ova &
# Upload image for openstack to swift
mkdir openstack
mv $IMAGE_NAME.qcow2 openstack/$IMAGE_NAME.qcow2
openstack object create automium-catalog-images openstack/$IMAGE_NAME.qcow2 &

# TODO travis will kill this in 10m
wait

# Upload image for vcd to swift (link to vsphere)
touch temp && swift upload automium-catalog-images --object-name vcd/$IMAGE_NAME.ova -H "X-Object-Manifest: automium-catalog-images/vsphere/$IMAGE_NAME.ova" temp
