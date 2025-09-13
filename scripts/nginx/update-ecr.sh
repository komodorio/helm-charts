#!/bin/bash

# check if regctl is installed
if ! command -v regctl &> /dev/null; then
    echo "regctl could not be found, please install it: https://regclient.org/install"
    exit 1
fi

# Authenticate with AWS ECR & Docker Hub
komo ci docker-login

NGINX_VERSION="1.27.5"

regctl image copy nginx:${NGINX_VERSION} public.ecr.aws/komodor-public/nginx:${NGINX_VERSION}
regctl image copy nginx:${NGINX_VERSION} komodorio/nginx:${NGINX_VERSION}