#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKERFILE="${REPO_ROOT}/scripts/nginx/Dockerfile"
VALUES="${REPO_ROOT}/charts/komodor-agent/values.yaml"

dockerfile_version="$(awk -F: '/^FROM nginx:/ {print $2; exit}' "${DOCKERFILE}")"

# `yq eval` is supported on every mikefarah-yq v4 release, including the
# v4.2.0 on the CI builder image (which doesn't accept the implicit form).
values_version="$(yq eval '.components.komodorKubectlProxy.image.tag' "${VALUES}")"

if [ -z "${dockerfile_version}" ]; then
    echo "ERROR: could not extract nginx version from ${DOCKERFILE}" >&2
    exit 1
fi
if [ -z "${values_version}" ] || [ "${values_version}" = "null" ]; then
    echo "ERROR: could not extract .components.komodorKubectlProxy.image.tag from ${VALUES}" >&2
    exit 1
fi

if [ "${dockerfile_version}" != "${values_version}" ]; then
    echo "ERROR: nginx version mismatch" >&2
    echo "  ${DOCKERFILE}: ${dockerfile_version}" >&2
    echo "  ${VALUES} (.components.komodorKubectlProxy.image.tag): ${values_version}" >&2
    echo "Update both files to the same tag." >&2
    exit 1
fi

echo "nginx version OK: ${dockerfile_version} (Dockerfile == values.yaml)"
