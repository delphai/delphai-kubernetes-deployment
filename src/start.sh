#! /usr/bin/env bash

# Variables
CHART_NAME=delphai-knative-service
CHART_VERSION=0.1.0
DELPHAI_ENVIROMENT=$INPUT_DELPHAI_ENVIROMENT

APP_ID=$INPUT_CLIENT_ID
SECRET=$INPUT_CLIENT_SECRET
TENANT_ID=$INPUT_TENANT_ID
ACR_SECRET=$INPUT_ACR_SECRET
REPO_NAME=$REPOSITORY_NAME
REPO_TAG=$REPOSITORY_REF_SLUG
IMAGE="delphai${DELPHAI_ENVIRONMENT}.azurecr.io/${REPO_NAME}:${REPO_TAG}"
DOMAIN="delphai.red"

# Login and set context
az login --service-principal --username $APP_ID --password $SECRET --tenant $TENANT_ID
az aks get-credentials -n delphai-${DELPHAI_ENVIROMENT} -g tf-cluster 
kubectl config current-context

# Helming
export HELM_EXPERIMENTAL_OCI=1
helm registry login delphai${DELPHAI_ENVIROMENT}.azurecr.io --username delphai${DELPHAI_ENVIROMENT} --password ${ACR_SECRET}
kubectl create namespace ${REPO_NAME} --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace ${REPO_NAME} -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update
helm upgrade --install --wait --atomic \
          ${REPO_NAME}-${REPO_TAG} \
          delphai/delphai-knative-service \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set gatewayPort=7070 \
          --set grpcPort=8080 \
          --set isPublic=true \
          --set domain=${DOMAIN}