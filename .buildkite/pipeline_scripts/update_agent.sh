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
CHART_VERSION="${6:-latest}"

komo ctx "${environment}"
helm repo add komodorio https://helm-charts.komodor.io
helm repo update

if [ "$CHART_VERSION" == "latest" ]; then
  CHART_VERSION=""
elif [ "$CHART_VERSION" == "rc" ]; then
  # Get latest RC version from the public repo
  RC_VER=$(helm search repo komodorio/komodor-agent --versions | grep '-RC' |  awk '{ print $2 }' | sort -V | tail -n 1)
  CHART_VERSION="--version $RC_VER"
else
  CHART_VERSION="--version $CHART_VERSION"
fi

helm get values "$RELEASE_NAME" -n "${NAMESPACE}" > current-values.yaml
helm upgrade --install "${RELEASE_NAME}"  komodorio/komodor-agent -n "${NAMESPACE}" --create-namespace -f current-values.yaml  --dry-run
helm upgrade --install "${RELEASE_NAME}"  komodorio/komodor-agent \
  --namespace="${NAMESPACE}" --create-namespace \
  --set clusterName="${CLUSTER_NAME}" \
  --set apiKey="$KOMODOR_AGENT_API_KEY" \
  --set imagePullSecret=docker-cfg-komodorio \
  --set allowedResources.secret=true \
  --set capabilities.event.redact="{.*KEY.*,.*key.*,.*BUGSNAG.*}" \
  --set tags="env:${environment}" $CHART_VERSION