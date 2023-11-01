#!/usr/bin/env bash

usage() {
    cat << EOF
Usage: $0 <RC-TAG>

  RC-TAG <string>  - Example: '1.2.0+RC1'
  sa.json          - Google service account key file should be in the same directory as this script
  RUN_TIMEOUT      - Env var, define for how long to run the scenarios (default: 10m)
EOF
}

create_cluster_name() {
    local input_string="$1"
    local formatted_string="${input_string//[^a-zA-Z0-9]/-}"
    local lowercase_string="$(echo $formatted_string | tr '[:upper:]' '[:lower:]')"
    echo "komodor-agent-${lowercase_string}"
}

auth_gcloud_with_sa() {
  if [[ ! -f sa.json ]]; then
      echo "sa.json file not found"
      exit 1
  fi

  gcloud auth activate-service-account --key-file=sa.json
  cp sa.json gcp-tf/sa.json
}

init_tf_workspace() {
  
  export GOOGLE_APPLICATION_CREDENTIALS=sa.json
  terraform init
  terraform workspace new "${CLUSTER_NAME}" || true
  terraform workspace select "${CLUSTER_NAME}"
}

cluster_cleanup(){
  cd gcp-tf
  terraform destroy -var="cluster_name=${CLUSTER_NAME}" -auto-approve -lock=false
}

setup_cluster() {
  trap cluster_cleanup EXIT

  # Create cluster
  terraform apply -var="cluster_name=${CLUSTER_NAME}" -auto-approve -lock=false
  if [[ $? -ne 0 ]]; then
      echo "Failed to create cluster"
      exit 1
  fi
}

get_kubeconfig(){
  terraform output -raw kubeconfig > ../kubeconfig.yaml
  chmod 400 ../kubeconfig.yaml
}

run_scenarios() {
  echo "Scenarios will be running for the next: ${TIMEOUT}"
  export CLUSTER_NAME=${CLUSTER_NAME}
  export CHART_VERSION="${RC_TAG}"
  timeout --preserve-status ${TIMEOUT} python3 /app/scenarios/main.py /app/kubeconfig.yaml
}

##############################################
#         Main
##############################################

# Handle input arguments and display usage
if [[ "$1" == "-h" ]]; then
    usage
    exit 0
elif [[ -z $1 ]]; then
    echo "RC-TAG is missing"
    usage
    exit 1
fi

set -x
TIMEOUT=${RUN_TIMEOUT:-"10m"}
RC_TAG="$1"
CLUSTER_NAME=$(create_cluster_name "$RC_TAG")

cd /app

auth_gcloud_with_sa

pushd gcp-tf
init_tf_workspace
setup_cluster
get_kubeconfig
popd

run_scenarios
