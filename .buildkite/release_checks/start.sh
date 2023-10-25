#!/usr/bin/env bash

cd /app

gcloud auth activate-service-account --key-file=sa.json

cp sa.json gcp-tf/sa.json
pushd gcp-tf
terraform init
terraform workspace new test || true
terraform workspace select test
terraform apply -var="cluster_name=test" -auto-approve
terraform output kubeconfig > ../kubeconfig.yaml
popd
timeout --preserve-status 10m python3 /app/scenarios/main.py kubeconfig.yaml