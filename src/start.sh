#! /usr/bin/env bash

# Variables
CHART_NAME=delphai-knative-service
CHART_VERSION=0.1.0
DELPHAI_ENVIROMENT=$INPUT_DELPHAI_ENVIROMENT

APP_ID=$INPUT_CLIENT_ID
SECRET=$INPUT_CLIENT_SECRET
TENANT_ID=$INPUT_TENANT_ID
REPO_NAME=$REPOSITORY_NAME
REPO_SLUG=$GITHUB_REF_SLUG
IMAGE="delphai${DELPHAI_ENVIROMENT}.azurecr.io/${REPO_NAME}:${REPO_SLUG}"
HTTPPORT=$INPUT_HTTPPORT
GRPCPORT=$INPUT_GRPCPORT
IS_PUBLIC=$INPUT_IS_PUBLIC
IS_UI=$INPUT_IS_UI


# Login and set context
az login --service-principal --username $APP_ID --password $SECRET --tenant $TENANT_ID
az aks get-credentials -n delphai-${DELPHAI_ENVIROMENT} -g tf-cluster 
kubectl config current-context
DOMAIN=$(kubectl get secret domain -o json --namespace default | jq .data.domain -r | base64 -d)



# Helming
kubectl create namespace ${REPO_NAME} --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace ${REPO_NAME} -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update
helm upgrade --install --wait --atomic \
          ${REPO_NAME}-${REPO_SLUG} \
          delphai/delphai-knative-service \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set httpPort=${HTTPPORT} \
          --set grpcPort=${GRPCPORT} \
          --set isPublic=${IS_PUBLIC} \
          --set isUi=${IS_UI} \
          --set domain=${DOMAIN}



echo -e "enviroment:${DELPHAI_ENVIROMENT},\nrepo_name:${REPO_NAME},\nrepo_slug:${REPO_SLUG},\nimage:${IMAGE},httpPort:${HTTPPORT}\ndomain:${DOMAIN},\nIs_public:${IS_PUBLIC},\nIs_Ui:${IS_UI}"
echo "██████  ███████ ██      ██████  ██   ██  █████  ██ ";
echo "██   ██ ██      ██      ██   ██ ██   ██ ██   ██ ██ ";
echo "██   ██ █████   ██      ██████  ███████ ███████ ██ ";
echo "██   ██ ██      ██      ██      ██   ██ ██   ██ ██ ";
echo "██████  ███████ ███████ ██      ██   ██ ██   ██ ██ ";
echo "                                                   ";
echo "                                                   ";
sleep 2
