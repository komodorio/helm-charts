#!/bin/bash

# Authenticate with AWS ECR & Docker Hub
komo ci docker-login

NGINX_VERSION="1.27.5"

regctl image copy nginx:${NGINX_VERSION} public.ecr.aws/komodor-public/nginx:${NGINX_VERSION}
