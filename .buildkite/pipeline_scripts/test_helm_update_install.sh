#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$(dirname $(realpath "$0"))
source "$SCRIPT_DIR/common.sh"


CURRENT_VERSION=$(get_current_version "komodor-agent")
NEW_VERSION=$(increment_version "$CURRENT_VERSION")

CHART_NAME="ci-test-$NEW_VERSION"
NAMESPACE="ci-test-namespace-$NEW_VERSION"

komo ctx staging
helm status -n "$NAMESPACE" "$CHART_NAME" && helm uninstall "$CHART_NAME" -n "$NAMESPACE" && sleep 10
BRANCH=$(git rev-parse --short HEAD)
git checkout master

echo "installing old helm chart on staging"
helm install "$CHART_NAME" charts/komodor-agent \
  --set clusterName="$CHART_NAME" \
  --namespace="$NAMESPACE" --create-namespace \
  --set apiKey="$KOMODOR_AGENT_STAGING_API_KEY" \
  -f staging-values.yaml

echo "upgrade to new helm chart on staging"
git checkout "$BRANCH"
helm get values "$CHART_NAME" -n "$NAMESPACE" > old-values.yaml &&
helm upgrade --install "$CHART_NAME" charts/komodor-agent -n "$NAMESPACE" -f old-values.yaml

echo "uninstalling new helm chart on staging"
helm uninstall "$CHART_NAME" -n "$NAMESPACE"
kubectl delete namespace "$NAMESPACE"
