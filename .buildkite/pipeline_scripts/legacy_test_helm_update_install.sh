#!/usr/bin/env bash
set -ex

pushd "$(dirname "$0")" > /dev/null
source common.sh


CURRENT_VERSION=$(get_current_version "k8s-watcher")
NEW_VERSION=$(increment_version "$CURRENT_VERSION")

CHART_NAME="ci-test-legacy-$NEW_VERSION"
NAMESPACE="ci-test-legacy-namespace-$NEW_VERSION"

komo ctx staging
helm status "${CHART_NAME}" && helm uninstall "${CHART_NAME}" && sleep 10
BRANCH=$(git rev-parse --short HEAD)
git checkout master
echo "installing old helm chart on staging"
helm install "${CHART_NAME}" charts/k8s-watcher \
  --set apiKey="$STAGING_API_KEY" \
  --set watcher.clusterName="ci-test-$NEW_VERSION" \
  --set imagePullSecret=docker-cfg-komodorio \
  --set namespace="${NAMESPACE}" \
  --set communications.serverHost=https://staging.app.komodor.com \
  --set communications.tasksServerHost=https://staging.app.komodor.com \
  --set communications.wsHost=wss://staging.app.komodor.com \
  --set capabilities.telemetry.enable=false \
  --set communications.telemetryServerHost=https://staging.telemetry.komodor.com \
  --set allowedResources.secret=true \
  --set capabilities.event.redact="{.*KEY.*,.*key.*,.*BUGSNAG.*}"

echo "upgrade to new helm chart on staging"
git checkout "$BRANCH"
helm upgrade --install "${CHART_NAME}" charts/k8s-watcher \
  --set apiKey="$STAGING_API_KEY" \
  --set watcher.clusterName="${CHART_NAME}" \
  --set imagePullSecret=docker-cfg-komodorio \
  --set namespace="${NAMESPACE}" \
  --set supervisor.enabled=true \
  --set watcher.serverHost=https://staging.app.komodor.com \
  --set watcher.tasksServerHost=https://staging.app.komodor.com \
  --set watcher.wsHost=wss://staging.app.komodor.com \
  --set watcher.telemetry.enable=false \
  --set watcher.telemetry.serverHost=https://staging.telemetry.komodor.com \
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
  --set metrics.enabled=true \
  --set watcher.actions.portforward=true \
  --set watcher.networkMapper.enable=false

helm uninstall "${CHART_NAME}"
