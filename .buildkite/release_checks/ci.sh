#!/usr/bin/env bash
set -x
# get current script file path
SCRIPT_DIR=$(dirname $(realpath "$0"))
pushd $SCRIPT_DIR

run_in_docker() {

  docker run -it --rm \
    -v $(pwd):/app \
    -e RUN_TIMEOUT=${RUN_TIMEOUT:-"10m"} \
    -e AGENT_API_KEY="${AGENT_API_KEY}" \
    634375685434.dkr.ecr.us-east-1.amazonaws.com/k8s-gcp-tools \
    "$@"
}

work_mode=$(buildkite-agent meta-data get job-mode || echo "ga")
rc_tag=$(buildkite-agent meta-data get rc-tag)

if [[ "$work_mode" != "ga" ]]; then
  echo "Running in '${work_mode}' mode, Skipping GA checks"
  exit 0
fi

echo $SA_KEY > sa.json
run_in_docker "./start.sh" "$rc_tag"
