#!/usr/bin/env bash
set -ex

environment="$1"
if [ -z "$environment" ]; then
  echo "ERROR: Environment variable environment is required"
  exit 1
fi

CLUSTER_NAME="$2"
if [ -z "$CLUSTER_NAME" ]; then
  echo "ERROR: Environment variable CLUSTER_NAME is required"
  exit 1
fi

RELEASE_NAME="${3:-komodor-agent}"
KOMODOR_AGENT_API_KEY="${4:-$API_KEY}"
NAMESPACE="${5:-komodor-agent}"

komo ctx "${environment}"
helm repo add komodorio https://helm-charts.komodor.io
helm repo update

helm get values "$RELEASE_NAME" -n "${NAMESPACE}" > current-values.yaml
helm upgrade --install "${RELEASE_NAME}"  komodorio/komodor-agent -n "${NAMESPACE}" --create-namespace -f current-values.yaml  --dry-run
helm upgrade --install "${RELEASE_NAME}"  komodorio/komodor-agent \
  --namespace="${NAMESPACE}" --create-namespace \
  --set clusterName="${CLUSTER_NAME}" \
  --set apiKey="$KOMODOR_AGENT_API_KEY" \
  --set imagePullSecret=docker-cfg-komodorio \
  --set allowedResources.secret=true \
  --set capabilities.event.redact="{.*KEY.*,.*key.*,.*BUGSNAG.*}" \
  --set tags="env:${environment}"