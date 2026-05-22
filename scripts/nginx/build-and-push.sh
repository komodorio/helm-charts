#!/bin/bash

# check if docker buildx is available
if ! docker buildx version &> /dev/null; then
    echo "docker buildx could not be found, please install it"
    exit 1
fi

# Authenticate with AWS ECR & Docker Hub
komo ci docker-login

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract nginx version from the Dockerfile (single source of truth).
NGINX_VERSION="$(awk -F: '/^FROM nginx:/ {print $2; exit}' "${SCRIPT_DIR}/Dockerfile")"
if [ -z "${NGINX_VERSION}" ]; then
    echo "Failed to read nginx version from ${SCRIPT_DIR}/Dockerfile"
    exit 1
fi

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
    --tag public.ecr.aws/komodor-public/nginx:${NGINX_VERSION} \
    --tag komodorio/nginx:${NGINX_VERSION} \
    --push \
    "${SCRIPT_DIR}"
