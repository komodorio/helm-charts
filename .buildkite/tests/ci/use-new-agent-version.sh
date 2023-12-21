#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CHART_PATH="${SCRIPT_DIR}/../../../charts/komodor-agent"

ver=$(buildkite-agent meta-data get "version" --job "${PARENT_JOB_ID}")
if [ $? -eq 0 ]; then
  echo "Updating app version to $ver"
  sed -i -e "s/appVersion.*/appVersion: $ver/g" "${CHART_PATH}/Chart.yaml"
fi
