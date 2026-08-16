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
SITE="${7:-us}"

komo ctx "${environment}"
helm repo add komodorio https://helm-charts.komodor.io
helm repo update

EXTRA_VALUES_ARG=""

if [ "$CHART_VERSION" == "latest" ]; then
  CHART_VERSION=""
elif [ "$CHART_VERSION" == "rc" ]; then
  # Get latest RC version from the public repo
  RC_VER=$(helm search repo komodorio/komodor-agent --versions --devel | grep '\-RC' |  awk '{ print $2 }' | sort -V | tail -n 1)
  CHART_VERSION="--version $RC_VER"
  EXTRA_VALUES_ARG="-f ./.buildkite/pipeline_scripts/production-rc-values-override.yaml"
else
  CHART_VERSION="--version $CHART_VERSION"
fi

if [ -f ./.buildkite/pipeline_scripts/${environment}-override-values.yaml ]; then
  EXTRA_VALUES_ARG="-f ./.buildkite/pipeline_scripts/${environment}-override-values.yaml"
fi

# Carry the live release's values forward, and preview that they still render.
#
# Both lines below assume the release already EXISTS, which breaks the first install on a new
# cluster in two different ways:
#   1. `helm get values` exits 1 with "release: not found";
#   2. the dry-run passes ONLY current-values.yaml — no --set clusterName/apiKey, no
#      production-values.yaml — so with empty values the chart fails its own validation
#      ("clusterName is a required value!").
# Under `set -e` either one kills the whole step, taking every other cluster in it down too.
#
# There is nothing to carry forward or preview on a cluster with no release, so skip both and let
# the real install below (which passes every required flag) do the work. Clusters that already have
# the release are completely unaffected — same two commands, same order, same output.
if helm get values "$RELEASE_NAME" -n "${NAMESPACE}" > current-values.yaml 2>/dev/null; then
  helm upgrade --install "${RELEASE_NAME}"  komodorio/komodor-agent -n "${NAMESPACE}" --create-namespace -f current-values.yaml  --dry-run
else
  echo "No existing '${RELEASE_NAME}' release in ${NAMESPACE} — first install on this cluster; skipping the values-preservation dry-run."
  : > current-values.yaml
fi
helm upgrade --install "${RELEASE_NAME}"  komodorio/komodor-agent \
  --namespace="${NAMESPACE}" --create-namespace \
  --set clusterName="${CLUSTER_NAME}" \
  --set apiKey="$KOMODOR_AGENT_API_KEY" \
  --set tags="env:${environment}" $CHART_VERSION \
  --set site="${SITE}" \
  -f ./.buildkite/pipeline_scripts/production-values.yaml $EXTRA_VALUES_ARG