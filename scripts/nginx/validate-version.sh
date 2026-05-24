#!/usr/bin/env bash
set -euo pipefail

if ! command -v yq >/dev/null 2>&1; then
    echo "ERROR: yq not installed; install mikefarah/yq v4+ (https://github.com/mikefarah/yq)" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKERFILE="${REPO_ROOT}/scripts/nginx/Dockerfile"
VALUES="${REPO_ROOT}/charts/komodor-agent/values.yaml"

# Extract nginx version from the Dockerfile.
# Reject multistage (>1 `FROM nginx:` lines) and unexpected suffixes
# (` AS build`, `@sha256:...`, etc.).
matches="$(grep -cE '^FROM[[:space:]]+nginx:' "${DOCKERFILE}" || true)"
if [ "${matches}" != "1" ]; then
    echo "ERROR: expected exactly one 'FROM nginx:...' line in ${DOCKERFILE}, found ${matches}" >&2
    exit 1
fi
dockerfile_version="$(sed -nE 's/^FROM[[:space:]]+nginx:([A-Za-z0-9._-]+)[[:space:]]*$/\1/p' "${DOCKERFILE}")"
if [ -z "${dockerfile_version}" ]; then
    echo "ERROR: 'FROM nginx:' line in ${DOCKERFILE} has an unexpected suffix (e.g. ' AS <stage>' or '@sha256:...'). Use a bare 'FROM nginx:<tag>' line." >&2
    exit 1
fi

# `yq eval` is supported on every mikefarah-yq v4 release, including the
# v4.2.0 on the CI builder image (which doesn't accept the implicit form).
values_version="$(yq eval '.components.komodorKubectlProxy.image.tag' "${VALUES}")"

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
