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

RELEASE_NAME="${3:-k8s-watcher}"
KOMODOR_AGENT_API_KEY="${4:-$API_KEY}"
NAMESPACE="komodor-legacy-chart"

komo ctx "${environment}"
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
#helm upgrade --install "${RELEASE_NAME}" komodorio/k8s-watcher \
#  --set apiKey="${KOMODOR_AGENT_API_KEY}" \
#  --set namespace="${NAMESPACE}" \
#  --reuse-values \
#  --dry-run

helm upgrade --install "${RELEASE_NAME}" komodorio/k8s-watcher \
  --set watcher.clusterName="${CLUSTER_NAME}" \
  --set namespace="${NAMESPACE}" \
  --set apiKey="${KOMODOR_AGENT_API_KEY}" \
  --set imagePullSecret=docker-cfg-komodorio \
  --set watcher.telemetry.enable=true \
  --set supervisor.enabled=true \
  --set watcher.collectHistory=true \
  --set watcher.nameDenylist="{leader,election}" \
  --set watcher.resources.secret=true \
  --set watcher.redact="{.*KEY.*,.*key.*,.*BUGSNAG.*}" \
  --set watcher.enableAgentTaskExecution=true \
  --set watcher.enableAgentTaskExecutionV2=true \
  --set watcher.allowReadingPodLogs=true \
  --set watcher.actions.basic=true \
  --set watcher.actions.advanced=true \
  --set watcher.enableHelm=true \
  --set helm.enableActions=true \
  --set watcher.actions.podExec=true \
  --set metrics.enabled=true  \
  --set watcher.actions.portforward=true \
  --set watcher.networkMapper.enable=true \
  --set tags="env:production"