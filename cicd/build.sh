#!/bin/bash

set -ex

# Set image name
export IMAGE_NAME=kubernetes-${CI_COMMIT_REF_NAME}-${CI_COMMIT_SHORT_SHA}

# Build image
packer build packer.json
sleep 10

mkdir openstack
openstack image save ${IMAGE_NAME} --file openstack/${IMAGE_NAME}.qcow2
openstack image show -f json ${IMAGE_NAME}  | jq -r '.checksum' > openstack/${IMAGE_NAME}.qcow2.md5sum

# Create container
openstack container create automium-catalog-images
swift post automium-catalog-images --read-acl ".r:*,.rlistings"

# Upload image for openstack to swift
swift upload automium-catalog-images openstack/${IMAGE_NAME}.qcow2
swift upload automium-catalog-images openstack/${IMAGE_NAME}.qcow2.md5sum

echo "Done"

