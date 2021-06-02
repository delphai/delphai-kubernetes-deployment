#! /usr/bin/env bash
set -e

if [ -z "$INPUT_IMAGE_SHA" ]; then
    IMAGE="delphai$INPUT_DELPHAI_ENVIROMENT.azurecr.io/$REPOSITORY_NAME:$GITHUB_REF_SLUG"
else
    IMAGE=$INPUT_IMAGE_SHA
fi


if [ -z "$INPUT_FILE_SHARES" ]; then
    FILE_SHARES=""
else
    FILE_SHARES=$INPUT_FILE_SHARES
fi

if [ "$REPOSITORY_NAME" == "delphai-ui" ]; then
    REPOSITORY_NAME="app"
fi

if [ "$GITHUB_REF_SLUG" = "master" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "GREEN" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "LIVE" ]; then
    RELEASE_NAME=$REPOSITORY_NAME
else
    RELEASE_NAME="$REPOSITORY_NAME-$GITHUB_REF_SLUG"
fi

if [ -z "$INPUT_SUBDOMAIN" ]; then
    echo "No Subdomain"
else
    RELEASE_NAME="$REPOSITORY_NAME-$INPUT_SUBDOMAIN"
fi

if [ -z "$INPUT_DOMAINS" ]; then
    DOMAINS=""
else
    DOMAINS=${INPUT_DOMAINS,,}
fi

if [ "$INPUT_DELPHAI_ENVIROMENT" == "GREEN" ] || [ "$INPUT_DELPHAI_ENVIROMENT" == "LIVE" ]; then
    echo "prduction" 
    DELPHAI_ENVIRONMENT_ENV_VAR=production
    az login --service-principal --username $INPUT_CLIENT_ID --password $INPUT_CLIENT_SECRET --tenant $INPUT_TENANT_ID
    az aks get-credentials -n delphai-${INPUT_DELPHAI_ENVIROMENT,,} -g tf-delphai-${INPUT_DELPHAI_ENVIROMENT,,}-cluster
elif [ "$INPUT_DELPHAI_ENVIROMENT" == "review" ]; then
    echo "review" 
    az login --service-principal --username $INPUT_CLIENT_ID --password $INPUT_CLIENT_SECRET --tenant $INPUT_TENANT_ID
    az aks get-credentials -n delphai-${INPUT_DELPHAI_ENVIROMENT} -g tf-${INPUT_DELPHAI_ENVIROMENT}-cluster 
else
    DELPHAI_ENVIRONMENT_ENV_VAR=$INPUT_DELPHAI_ENVIROMENT
    az login --service-principal --username $INPUT_CLIENT_ID --password $INPUT_CLIENT_SECRET --tenant $INPUT_TENANT_ID
    az aks get-credentials -n delphai-${INPUT_DELPHAI_ENVIROMENT,,} -g tf-cluster 
fi
echo "IMAGE:${IMAGE}\nENVIRONMENT:${DELPHAI_ENVIRONMENT_ENV_VAR}\nRELEASE:${RELEASE_NAME}\nREOSITORY:$REPOSITORY_NAME"
echo "BRANCH:$GITHUB_REF_SLUG\nHTTP:$INPUT_HTTPPORT\nDOMAIN:${DOMAIN}\nDOMAINS:${DOMAINS}\nIs_Ui:$INPUT_IS_UI"
# Azure Login and set kubernetes cluster context

kubectl config current-context


# Create namespace - patch service principle - set domain variable 
kubectl create namespace $REPOSITORY_NAME --output yaml --dry-run=client | kubectl apply -f -
kubectl patch serviceaccount default --namespace $REPOSITORY_NAME -p "{\"imagePullSecrets\": [{\"name\": \"acr-credentials\"}]}"
DOMAIN=$(kubectl get secret domain -o json --namespace default | jq .data.domain -r | base64 -d)

# Helm
helm repo add delphai https://delphai.github.io/helm-charts && helm repo update



# Helm Delphai with Ui
if  [ "$INPUT_IS_UI" == "true" ] && [ "$INPUT_IS_GRPC" == "false" ] ; then
    echo "Using helm delphai-with-ui"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-with-ui \
          --namespace=$REPOSITORY_NAME \
          --set image=${IMAGE} \
          --set httpPort=$INPUT_HTTPPORT \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} \
          --set subdomain=$INPUT_SUBDOMAIN
    kubectl patch deployment ${RELEASE_NAME} --namespace $REPOSITORY_NAME -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"

elif  [ "$INPUT_IS_UI" == "false" ] && [ "$INPUT_MICROSERVICE" == "true" ] ; then
    echo "Using helm delphai-microservice service"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-microservice \
          --namespace=$REPOSITORY_NAME \
          --set image=${IMAGE} \
          --set replicas=${INPUT_REPLICAS:-1} \
          --set gatewayPort=7070 \
          --set deployGateway=false\
          --set authRequired=false\
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set fileShares=${FILE_SHARES}

elif   [ "$INPUT_IS_UI" == "false" ] && [ "$INPUT_IS_GRPC" == "false" ] ; then
    echo "Using helm delphai-knative service"
    helm upgrade --install --wait --atomic --reset-values\
          ${RELEASE_NAME} \
          delphai/delphai-knative-service \
          --namespace=$REPOSITORY_NAME \
          --set image=${IMAGE} \
          --set httpPort=$INPUT_HTTPPORT \
          --set grpcPort=$INPUT_GRPCPORT \
          --set isPublic=$INPUT_IS_PUBLIC \
          --set isUi=$INPUT_IS_UI \
          --set domain=${DOMAIN} \
          --set domains=${DOMAINS} \
          --set minScale=${INPUT_MIN_SCALE} \
          --set concurrency=${INPUT_CONCURRENCY} \
          --set delphaiEnvironment=${DELPHAI_ENVIRONMENT_ENV_VAR} 
fi