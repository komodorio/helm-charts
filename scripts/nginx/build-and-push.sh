#!/bin/bash

# check if docker buildx is available
if ! docker buildx version &> /dev/null; then
    echo "docker buildx could not be found, please install it"
    exit 1
fi

# Authenticate with AWS ECR & Docker Hub
# komo ci docker-login

NGINX_VERSION="1.29.4-alpine3.23"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create/use buildx builder for multi-platform builds
BUILDER_NAME="nginx-multiarch"
if ! docker buildx inspect ${BUILDER_NAME} &> /dev/null; then
    docker buildx create --name ${BUILDER_NAME} --use
else
    docker buildx use ${BUILDER_NAME}
fi

# Build and push multi-arch image to both registries
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg NGINX_VERSION=${NGINX_VERSION} \
    --tag public.ecr.aws/komodor-public/nginx:${NGINX_VERSION} \
    --tag komodorio/nginx:${NGINX_VERSION} \
    --push \
    "${SCRIPT_DIR}"
