#!/usr/bin/env bash

cd /app

gcloud auth activate-service-account --key-file=sa.json

ln -s sa.json gcp-tf/sa.json
terraform workspace new test || true
terraform workspace select test
terraform init
terraform apply -var="cluster_name=test" -auto-approve
terraform output kubeconfig > ../kubeconfig.yaml

timeout --preserve-status 10m python3 /app/main.py kubeconfig.yaml