#!/usr/bin/env bash

# get current script file path
SCRIPT_DIR=$(dirname $(realpath "$0"))
pushd $SCRIPT_DIR

run_in_docker() {
  command="$1"
  docker run -it --rm \
    -v $(pwd):/app \
    634375685434.dkr.ecr.us-east-1.amazonaws.com/k8s-gcp-tools \
    "${command}"
}

echo $SA_KEY > sa.json
run_in_docker "./start.sh"
