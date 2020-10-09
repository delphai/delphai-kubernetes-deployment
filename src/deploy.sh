#! /usr/bin/env bash

DELPHAI_ENVIRONMENT=$INPUT_DELPHAI_ENVIROMENT
ACR_PASSWORD=$INPUT_REGISTRY_PASSWORD
REPO_NAME=$REPOSITORY_NAME
REPO_TAG=$REPOSITORY_REF
IMAGE="delphai${DELPHAI_ENVIRONMENT}.azurecr.io/${REPO_NAME}:${REPO_TAG}"
CHART_NAME=delphai-knative-service
CHART_VERSION=0.1.0
GATEWAY_PORT=7070
GRPC_PORT=8080
IS_PUBLIC=true
DOMAIN=delphai.black

# Get Docker
python /app/src/main.py
# Build Docker Image
docker build -t ${IMAGE} .
az acr login --name delphai${DELPHAI_ENVIRONMENT} --resource-group delphai-${DELPHAI_ENVIRONMENT} -p ${ACR_PASSWORD}