#!/bin/bash

ECR_REPO="public.ecr.aws/komodor-public"
IMAGE_NAME="telegraf"
PLATFORMS=("linux/amd64" "linux/arm64/v8")

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <telegraf-tag>"
    exit 1
fi

IMAGE_TAG="$1"

# Authenticate with AWS ECR & Docker Hub
komo ci docker-login

# Pull, tag, and push for each platform
for PLATFORM in "${PLATFORMS[@]}"; do
    docker pull --platform "${PLATFORM}" "${IMAGE_NAME}:${IMAGE_TAG}"

    PLATFORM_TAG=${PLATFORM//\//_}
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}-${PLATFORM_TAG}"

    docker push "${ECR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}-${PLATFORM_TAG}"
done

# Create and push the manifest
MANIFEST_TAG="${IMAGE_NAME}:${IMAGE_TAG}"
docker manifest create "${ECR_REPO}/${MANIFEST_TAG}" \
    "${ECR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}-linux_amd64" \
    "${ECR_REPO}/${IMAGE_NAME}:${IMAGE_TAG}-linux_arm64_v8" \
    --amend

# Push the manifest
docker manifest push "${ECR_REPO}/${MANIFEST_TAG}"

echo "Images and manifest pushed successfully to ECR."
