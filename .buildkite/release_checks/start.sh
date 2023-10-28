#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <RC-TAG>"
  echo "  RC-TAG <string> - Example: 'komodor-agent/1.2.0+RC1'"
  echo "  sa.json: Google service account key file should be in the same directory as this script"
  echo "  RUN_TIMEOUT: Env var, define for how long to run the scenarios (default: 10m)"
}

function create_cluster_name() {
    local input_string="$1"
    # Convert to lowercase
    local lowercase_string="${input_string,,}"
    # Replace any characters that are not lowercase letters, numbers, or hyphens with hyphens
    local formatted_string="${lowercase_string//[^a-z0-9]/-}"
    # Remove any non-alphanumeric characters at the beginning or end of the string
    formatted_string="${formatted_string%%[-]*}"
    formatted_string="${formatted_string##[-]*}"
    echo "$formatted_string"
}

if [[ "$1" == "-h" ]]; then
  usage
  exit 0
fi

if [ -z $1 ]; then
  echo "RC-TAG is missing"
  usage
  exit 1
fi

set -x

TIMEOUT=${RUN_TIMEOUT:-"10m"}
RC_TAG="$1"
CLUSTER_NAME=$(create_cluster_name "$RC_TAG")

cd /app


if [ ! -f sa.json ]; then
  echo "sa.json file not found"
  exit 1
fi

gcloud auth activate-service-account --key-file=sa.json

cp sa.json gcp-tf/sa.json

pushd gcp-tf
export GOOGLE_APPLICATION_CREDENTIALS=sa.json
terraform init
terraform workspace new "${CLUSTER_NAME}" || true
terraform workspace select "${CLUSTER_NAME}"
terraform apply -var="cluster_name=${CLUSTER_NAME}" -auto-approve

if [ $? -ne 0 ]; then
  echo "Failed to create cluster"
  exit 1
fi

terraform output -raw kubeconfig > ../kubeconfig.yaml
chmod 400 ../kubeconfig.yaml
popd
echo "Scenarios will be running for the next: ${TIMEOUT}"
timeout --preserve-status ${TIMEOUT} python3 /app/scenarios/main.py /app/kubeconfig.yaml