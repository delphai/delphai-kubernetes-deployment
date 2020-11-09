#! /usr/bin/env bash
set -e
# Variables
CHART_NAME=delphai-knative-service
CHART_VERSION=0.1.0
DELPHAI_ENVIROMENT=$INPUT_DELPHAI_ENVIROMENT

APP_ID=$INPUT_CLIENT_ID
SECRET=$INPUT_CLIENT_SECRET
TENANT_ID=$INPUT_TENANT_ID
REPO_NAME=$REPOSITORY_NAME
REPO_SLUG=$GITHUB_REF_SLUG
IMAGE=$INPUT_IMAGE_SHA
HTTPPORT=$INPUT_HTTPPORT
GRPCPORT=$INPUT_GRPCPORT
IS_PUBLIC=$INPUT_IS_PUBLIC
IS_UI=$INPUT_IS_UI
IS_GRPC=$INPUT_IS_GRPC
IS_MICROSERVICE=$INPUT_MICROSERVICE
FILE_SHARES=$INPUT_FILE_SHARES

if [ -z "$IMAGE" ]; then
    echo "Atrifact not set"
    IMAGE="delphai${DELPHAI_ENVIROMENT}.azurecr.io/${REPO_NAME}:${REPO_SLUG}"
fi

if [ ! -z "$FILE_SHARES" ]; then
    IFS=', ' read -r -a FILES <<< ${FILE_SHARES} 
fi

if [ "${REPO_NAME}" == "delphai-ui" ]; then
    REPO_NAME="app"
fi

if [ "${REPO_SLUG}" = "master" ]; then
    RELEASE_NAME=${REPO_NAME}
else
    RELEASE_NAME=${REPO_NAME}-${REPO_SLUG}
fi

# Login and set context
az login --service-principal --username $APP_ID --password $SECRET --tenant $TENANT_ID
az aks get-credentials -n delphai-${DELPHAI_ENVIROMENT} -g tf-cluster 
kubectl config current-context
DOMAIN=$(kubectl get secret domain -o json --namespace default | jq .data.domain -r | base64 -d)

#Helming
kubectl create namespace ${REPO_NAME} --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace ${REPO_NAME} -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update

if  [ "${IS_UI}" == "true" ] && [ "${IS_MICROSERVICE}" == "false" ] ; then
    echo "Using helm delphai-with-ui"
    helm upgrade --install --wait --atomic \
          ${RELEASE_NAME} \
          delphai/delphai-with-ui \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set httpPort=${HTTPPORT} \
          --set domain=${DOMAIN} \
          --set delphaiEnvironment=${DELPHAI_ENVIROMENT}
elif   [ "${IS_UI}" == "false" ] && [ "${IS_MICROSERVICE}" == "false" ] ; then
    echo "Using helm delphai-knative service"
    helm upgrade --install --wait --atomic \
          ${RELEASE_NAME} \
          delphai/delphai-knative-service \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set httpPort=${HTTPPORT} \
          --set grpcPort=${GRPCPORT} \
          --set isPublic=${IS_PUBLIC} \
          --set isUi=${IS_UI} \
          --set domain=${DOMAIN} \
          --set delphaiEnvironment=${DELPHAI_ENVIROMENT} 
elif  [ "${IS_UI}" == "false" ] && [ "${IS_MICROSERVICE}" == "true" ] ; then
    echo "Using helm delphai-microservice service"
    helm upgrade --install --wait --atomic \
          ${RELEASE_NAME} \
          delphai/delphai-microservice \
          --namespace=${REPO_NAME} \
          --set image=${IMAGE} \
          --set replicas=1 \
          --set gatewayPort=7070 \
          --set deployGateway=false\
          --set authRequired=false\
          --set delphaiEnvironment=${DELPHAI_ENVIROMENT} \
          --set domain=${DOMAIN} 

fi
echo -e "\e[32mImportantInfo"
echo -e "image:${IMAGE},\nenviroment:${DELPHAI_ENVIROMENT},\nrelease:${RELEASE_NAME},\nrepo_name:${REPO_NAME},\nrepo_slug:${REPO_SLUG},\nhttpPort:${HTTPPORT}\ndomain:${DOMAIN},\nIs_public:${IS_PUBLIC},\nIs_Ui:${IS_UI}\nis_runner:${IS_RUNNER}\n\n\n"
echo "██████  ███████ ██      ██████  ██   ██  █████  ██ ";
echo "██   ██ ██      ██      ██   ██ ██   ██ ██   ██ ██ ";
echo "██   ██ █████   ██      ██████  ███████ ███████ ██ ";
echo "██   ██ ██      ██      ██      ██   ██ ██   ██ ██ ";
echo "██████  ███████ ███████ ██      ██   ██ ██   ██ ██ ";
echo "                                                   ";
echo "                                                   ";
