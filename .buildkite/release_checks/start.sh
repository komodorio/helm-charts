#!/usr/bin/env bash
set -x

TIMEOUT=${RUN_TIMEOUT:-"10m"}

cd /app

gcloud auth activate-service-account --key-file=sa.json

cp sa.json gcp-tf/sa.json

pushd gcp-tf
export GOOGLE_APPLICATION_CREDENTIALS=sa.json
terraform init
terraform workspace new test || true
terraform workspace select test
terraform apply -var="cluster_name=test" -auto-approve

if [ $? -ne 0 ]; then
  echo "Failed to create cluster"
  exit 1
fi

terraform output -raw kubeconfig > ../kubeconfig.yaml
chmod 400 ../kubeconfig.yaml
popd
echo "Scenarios will be running for the next: ${TIMEOUT}"
timeout --preserve-status ${TIMEOUT} python3 /app/scenarios/main.py /app/kubeconfig.yaml