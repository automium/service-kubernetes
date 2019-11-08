#!/bin/bash

IMAGE_NAME=automium/service-kubernetes
docker build --no-cache --pull --tag "$IMAGE_NAME" .
docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASS"
docker tag "$IMAGE_NAME" "${IMAGE_NAME}:${CI_JOB_ID}"
#docker tag "$IMAGE_NAME" "${IMAGE_NAME}:latest"
docker push "${IMAGE_NAME}:${CI_JOB_ID}"
#docker push "${IMAGE_NAME}:latest"
