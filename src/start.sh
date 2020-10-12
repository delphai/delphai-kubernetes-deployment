#! /usr/bin/env bash

CHART_NAME=delphai-knative-service
CHART_VERSION=0.1.0
DELPHAI_ENVIROMENT=$INPUT_DELPHAI_ENVIROMENT
APP_ID=$INPUT_CLIENT_ID
PASSWORD=$INPUT_CLIENT_SECRET
TENANT_ID=$INPUT_TENANT_ID
REPO_NAME=$REPOSITORY_NAME
REPO_TAG=$REPOSITORY_REF_SLUG
IMAGE="delphai${DELPHAI_ENVIRONMENT}.azurecr.io/${REPO_NAME}:${REPO_TAG}"
DOMAIN="delphai.red"
apt-get install jq -y


az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID
az aks get-credentials -n delphai-${DELPHAI_ENVIROMENT} -g tf-cluster 
kubectl config current-context
kubectl get pods --namespace delphai-boilerplate 

export HELM_EXPERIMENTAL_OCI=1

PASSWORD=$(az acr credential show --name delphai${DELPHAI_ENVIROMENT} --resource-group tf-container-registry | jq .passwords[0].value -r)
helm registry login delphai${DELPHAI_ENVIROMENT}.azurecr.io --username delphai${DELPHAI_ENVIROMENT} --password ${PASSWORD}
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update
kubectl create namespace ${REPO_NAME} --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace ${REPO_NAME} -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
helm upgrade --install \
  --namespace ${REPO_NAME} \
  --set image=${IMAGE} \
  --set gatewayPort=7070 \
  --set grpcPort=8080 \
  --set isPublic=${IS_PUBLIC} \
  --set domain=${DOMAIN} \
  ${REPO_NAME}-${REPO_TAG} \
  ./.chart/${CHART_NAME}


