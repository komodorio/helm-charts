#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$(dirname $(realpath "$0"))
source "$SCRIPT_DIR/common.sh"

CURRENT_VERSION=$(get_current_version "komodor-agent")
NEW_VERSION=$(increment_version "$CURRENT_VERSION")
CHART_NAME="ci-test-$NEW_VERSION"
NAMESPACE="ci-test-namespace-$NEW_VERSION"

komo ctx staging
helm status "$CHART_NAME" -n "$NAMESPACE" && helm uninstall "$CHART_NAME" -n "$NAMESPACE" && sleep 10
kubectl delete namespace "$NAMESPACE" && kubectl wait --for=delete namespace/"$NAMESPACE" --timeout=3m || echo "namespace $NAMESPACE not found"

echo "installing new helm chart on staging"
helm install "$CHART_NAME" charts/komodor-agent \
  --set clusterName="$CHART_NAME" \
  --namespace="$NAMESPACE" --create-namespace \
  --set apiKey="$KOMODOR_AGENT_STAGING_API_KEY" \
  -f "${SCRIPT_DIR}/staging-values.yaml"

echo "uninstalling new helm chart on staging"
helm uninstall "$CHART_NAME" -n "$NAMESPACE"
kubectl delete namespace "$NAMESPACE"
kubectl wait --for=delete namespace/"$NAMESPACE" --timeout=3m