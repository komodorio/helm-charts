#!/usr/bin/env bash
set -euo pipefail

# check if docker buildx is available
if ! docker buildx version &> /dev/null; then
    echo "docker buildx could not be found, please install it"
    exit 1
fi

# Authenticate with AWS ECR & Docker Hub
komo ci docker-login --hub-login true --ecr-login true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"

# Extract nginx version from the Dockerfile (single source of truth).
# Reject multistage (>1 `FROM nginx:` lines) and unexpected suffixes
# (` AS build`, `@sha256:...`, etc.).
matches="$(grep -cE '^FROM[[:space:]]+nginx:' "${DOCKERFILE}" || true)"
if [ "${matches}" != "1" ]; then
    echo "ERROR: expected exactly one 'FROM nginx:...' line in ${DOCKERFILE}, found ${matches}" >&2
    exit 1
fi
NGINX_VERSION="$(sed -nE 's/^FROM[[:space:]]+nginx:([A-Za-z0-9._-]+)[[:space:]]*$/\1/p' "${DOCKERFILE}")"
if [ -z "${NGINX_VERSION}" ]; then
    echo "ERROR: 'FROM nginx:' line in ${DOCKERFILE} has an unexpected suffix (e.g. ' AS <stage>' or '@sha256:...'). Use a bare 'FROM nginx:<tag>' line." >&2
    exit 1
fi

# Create/use buildx builder for multi-platform builds
BUILDER_NAME="nginx-multiarch"
if ! docker buildx inspect "${BUILDER_NAME}" &> /dev/null; then
    docker buildx create --name "${BUILDER_NAME}" --use
else
    docker buildx use "${BUILDER_NAME}"
fi

# Build and push multi-arch image to both registries
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "public.ecr.aws/komodor-public/nginx:${NGINX_VERSION}" \
    --tag "komodorio/nginx:${NGINX_VERSION}" \
    --push \
    "${SCRIPT_DIR}"
