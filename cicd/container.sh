#!/bin/bash

IMAGE_NAME=automium/service-kubernetes
TAG_NAME=kubernetes-${CI_COMMIT_REF_NAME}-${CI_COMMIT_SHORT_SHA}
docker build --no-cache --pull --tag "$IMAGE_NAME" .
docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASS"
docker tag "$IMAGE_NAME" "${IMAGE_NAME}:${TAG_NAME}"
docker push "${IMAGE_NAME}:${TAG_NAME}"
