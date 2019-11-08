#!/bin/bash

IMAGE_NAME=automium/service-kubernetes
KUBERNETES_VERSION="1.15.3"
TAG_NAME=kubernetes-v${KUBERNETES_VERSION}-${CI_COMMIT_SHORT_SHA}
docker build --no-cache --pull --tag "$IMAGE_NAME" .
docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASS"
docker tag "$IMAGE_NAME" "${IMAGE_NAME}:${CI_COMMIT_SHORT_SHA}"
#docker tag "$IMAGE_NAME" "${IMAGE_NAME}:latest"
docker push "${IMAGE_NAME}:${CI_COMMIT_SHORT_SHA}"
#docker push "${IMAGE_NAME}:latest"