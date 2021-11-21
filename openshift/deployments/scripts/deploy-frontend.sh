#!/bin/bash

# **************** Global variables
root_folder=$(cd $(dirname $0); cd ../../../; pwd)
# secrets
export APPID_SECRETS_TEMPLATE_FILE="appid-secrets-template.yaml"
export POSTGRES_SECRETS_TEMPLATE_FILE="postgres-secrets-template.yaml"
export APPID_SECRETS_FILE="appid-secrets.yaml"
export POSTGRES_SECRETS_FILE="postgres-secrets.yaml"
# configmap
export FRONTEND_TEMPLATE_CONFIGMAP_FILE="configmap-frontend-template.yaml"
export FRONTEND_CONFIGMAP_FILE="configmap-frontend.yaml"
export URL_PRODUCTS="xxx"
export URL_ORDERS="xxx"
export URL_CATEGORIES="xxx"
export APP_CATEGORY_NAME="Movies"
export APP_HEADLINE="Frontend OpenShift"
export APP_ROOT="'/'"
# build config
export GIT_REPO="https://github.com/IBM/multi-tenancy"
export FRONTEND_TEMPLATE_BUILD_CONFIG_FILE="frontend-build-config-template.yaml"
export FRONTEND_BUILD_CONFIG_FILE="frontend-build-config.yaml"
# image stream config
export FRONTEND_IMAGESTREAM_CONFIG_FILE="frontend-imagestream-config.yaml"
export FRONTEND_TEMPLATE_IMAGESTREAM_CONFIG_FILE="frontend-template-imagestream-config.yaml"
export FRONTEND_IMAGESTREAM_JSON="frontend-imagestream.json"
export FRONTEND_IMAGESTREAM_DOCKERIMAGEREFERENCE=""
# deployment config
export FRONTEND_TEMPLATE_DEPLOYMENT_CONFIG_FILE="frontend-deployment-config-template.yaml"
export FRONTEND_DEPOLYMENT_CONFIG_FILE="frontend-deployment-config.yaml"
# service config
export FRONTEND_SERVICE_CONFIG_FILE="frontend-service-config.yaml"
# route config
export FRONTEND_TEMPLATE_ROUTE_CONFIGE_FILE="frontend-template-route-config.yaml"
export FRONTEND_ROUTE_CONFIGE_FILE="frontend-route-config.yaml"

# OpenShift
export OS_PROJECT="multi-tenancy-openshift"
export OS_BUILD="frontend-build"
export OS_IMAGE_STREAM="frontend-image-stream"
export OS_DOMAIN=""
export OS_SERVICE="frontend-service"


# **************** Load environments variables

# change the standard output
exec 3>&1

# **********************************************************************************
# Functions definition
# **********************************************************************************

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function createFrontendSecrets () {
  CFG_FILE=${root_folder}/local.env
  
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  echo "local.env exists: $CFG_FILE"
  source $CFG_FILE
  
  echo "-> prepare app id secrets"
  TMP_FILE_1=tmp_frontend_secrect_1.yaml
  TMP_FILE_2=tmp_frontend_secrect_2.yaml

  KEY_TO_REPLACE=APPID_CLIENT_ID
  sed "s+$KEY_TO_REPLACE+$APPID_CLIENT_ID+g" "${root_folder}/openshift/deployments/secrets/$APPID_SECRETS_TEMPLATE_FILE" > ${root_folder}/openshift/deployments/secrets/$TMP_FILE_1

  KEY_TO_REPLACE=APPID_DISCOVERYENDPOINT
  sed "s+$KEY_TO_REPLACE+$APPID_DISCOVERYENDPOINT+g" "${root_folder}/openshift/deployments/secrets/$TMP_FILE_1" > ${root_folder}/openshift/deployments/secrets/$TMP_FILE_2

  KEY_TO_REPLACE=APPID_AUTH_SERVER_URL
  sed "s+$KEY_TO_REPLACE+$APPID_AUTH_SERVER_URL+g" "${root_folder}/openshift/deployments/secrets/$TMP_FILE_2" > ${root_folder}/openshift/deployments/secrets/$APPID_SECRETS_FILE

  echo "-> create app id secrets"
  oc apply -f "${root_folder}/openshift/deployments/secrets/$APPID_SECRETS_FILE"

  rm -f ${root_folder}/openshift/deployments/secrets/$TMP_FILE_1
  rm -f ${root_folder}/openshift/deployments/secrets/$TMP_FILE_2
}

function createFrontendConfigMap () { 
  echo "-> create configmap for frontend"
  TMP_FILE_1=tmp_frontend_config_1.yaml
  TMP_FILE_2=tmp_frontend_config_2.yaml

  KEY_TO_REPLACE=URL_PRODUCTS_1
  sed "s+$KEY_TO_REPLACE+$URL_PRODUCTS+g" "${root_folder}/openshift/deployments/configmaps/$FRONTEND_TEMPLATE_CONFIGMAP_FILE" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1

  KEY_TO_REPLACE=URL_ORDERS_1
  sed "s+$KEY_TO_REPLACE+$URL_ORDERS+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2

  KEY_TO_REPLACE=URL_CATEGORIES_1
  sed "s+$KEY_TO_REPLACE+$URL_CATEGORIES+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1

  KEY_TO_REPLACE=APP_CATEGORY_NAME_1
  sed "s+$KEY_TO_REPLACE+$APP_CATEGORY_NAME+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2

  KEY_TO_REPLACE=APP_HEADLINE_1
  sed "s+$KEY_TO_REPLACE+$APP_HEADLINE+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1

  KEY_TO_REPLACE=APP_ROOT_1
  sed "s+$KEY_TO_REPLACE+$APP_ROOT+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1" > ${root_folder}/openshift/deployments/configmaps/$FRONTEND_CONFIGMAP_FILE

  echo "-> create app id secrets"
  oc apply -f "${root_folder}/openshift/deployments/configmaps/$FRONTEND_CONFIGMAP_FILE"

  rm -f ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1
  rm -f ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2
}

function createAndApplyBuildConfig () {  
  echo "-> delete imagestream"
  oc delete imagestream $OS_IMAGE_STREAM
  oc describe imagestream $OS_IMAGE_STREAM

  echo "-> delete build config"
  oc delete build $OS_BUILD
  oc describe bc/$OS_BUILD

  echo "-> prepare image stream"
  KEY_TO_REPLACE=IMAGE_STREAM_1
  sed "s+$KEY_TO_REPLACE+$OS_IMAGE_STREAM+g" "${root_folder}/openshift/deployments/image-stream/$FRONTEND_TEMPLATE_IMAGESTREAM_CONFIG_FILE" > ${root_folder}/openshift/deployments/image-stream/$FRONTEND_IMAGESTREAM_CONFIG_FILE
 
  echo "-> create image stream" 
  oc apply -f "${root_folder}/openshift/deployments/image-stream/$FRONTEND_IMAGESTREAM_CONFIG_FILE"
  oc describe imagestream
  #oc describe is/$OS_IMAGE_STREAM
  
  echo "-> prepare build config"
  KEY_TO_REPLACE=GIT_REPO_1
  sed "s+$KEY_TO_REPLACE+$GIT_REPO+g" "${root_folder}/openshift/deployments/build-configuration/$FRONTEND_TEMPLATE_BUILD_CONFIG_FILE" > ${root_folder}/openshift/deployments/build-configuration/$tmp.yaml
  KEY_TO_REPLACE=IMAGE_STREAM_1 
  sed "s+$KEY_TO_REPLACE+$OS_IMAGE_STREAM+g" "${root_folder}/openshift/deployments/build-configuration/$tmp.yaml" > ${root_folder}/openshift/deployments/build-configuration/$FRONTEND_BUILD_CONFIG_FILE
  rm -f ./tmp.yaml

  echo "-> create build config"
  oc apply -f "${root_folder}/openshift/deployments/build-configuration/$FRONTEND_BUILD_CONFIG_FILE"
  
  echo "-> verify build config"
  oc describe bc/$OS_BUILD
  
  echo "-> start build"
  oc start-build $OS_BUILD
  
  echo "-> verify build logs"
  oc logs -f bc/$OS_BUILD
  
  echo "-> verify image stream"
  oc describe imagestream
  
  echo "-> extract image reference: $OS_IMAGE_STREAM"
  oc get imagestream "$OS_IMAGE_STREAM" -o json > ../image-stream/$FRONTEND_IMAGESTREAM_JSON
  DOCKERIMAGEREFERENCE=$(cat ../image-stream/$FRONTEND_IMAGESTREAM_JSON | jq '.status.dockerImageRepository' | sed 's/"//g')
  TAG=$(cat ../image-stream/$FRONTEND_IMAGESTREAM_JSON | jq '.status.tags[].tag' | sed 's/"//g')
  rm -f ../image-stream/$FRONTEND_IMAGESTREAM_JSON
  FRONTEND_IMAGESTREAM_DOCKERIMAGEREFERENCE=$DOCKERIMAGEREFERENCE:$TAG
  echo "-> image reference : $FRONTEND_IMAGESTREAM_DOCKERIMAGEREFERENCE"
}

function createDeployment () {
  echo "-> prepare deployment config"
  KEY_TO_REPLACE=CONTAINER_IMAGE_1
  echo "-> image: $FRONTEND_IMAGESTREAM_DOCKERIMAGEREFERENCE"
  sed "s+$KEY_TO_REPLACE+$FRONTEND_IMAGESTREAM_DOCKERIMAGEREFERENCE+g" "${root_folder}/openshift/deployments/deployments/$FRONTEND_TEMPLATE_DEPLOYMENT_CONFIG_FILE" > ${root_folder}/openshift/deployments/deployments/$FRONTEND_DEPOLYMENT_CONFIG_FILE
  
  echo "-> create deployment config"
  oc apply -f "${root_folder}/openshift/deployments/deployments/$FRONTEND_DEPOLYMENT_CONFIG_FILE"
}

function createProject () {
  echo "-> delete project"
  oc delete project "$OS_PROJECT"
  echo "-> status project"
  oc status
  echo "-> verify project is deleted"
  echo "-> press return"
  read
  echo "-> create project"
  oc new-project "$OS_PROJECT"
}

function createService () {
  echo "-> create service config"
  oc apply -f "${root_folder}/openshift/deployments/services/$FRONTEND_SERVICE_CONFIG_FILE"
}

function createRoute () {
  echo "-> get ingress domain of the cluster"
  OS_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})
  echo "-> domain: $OS_DOMAIN"
  echo "-> prepare route"
  KEY_TO_REPLACE=OC_DOMAIN_1
  sed "s+$KEY_TO_REPLACE+$OS_DOMAIN+g" "${root_folder}/openshift/deployments/routes/$FRONTEND_TEMPLATE_ROUTE_CONFIGE_FILE" > ${root_folder}/openshift/deployments/routes/tmp.yaml
  KEY_TO_REPLACE=OC_SERVICE_1
  sed "s+$KEY_TO_REPLACE+$OS_SERVICE+g" "${root_folder}/openshift/deployments/routes/tmp.yaml" > ${root_folder}/openshift/deployments/routes/$FRONTEND_ROUTE_CONFIGE_FILE
  echo "-> create route"
  oc apply -f "${root_folder}/openshift/deployments/routes/$FRONTEND_ROUTE_CONFIGE_FILE"
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "--------------------"
echo " 1. Create project"
echo "--------------------"
createProject

echo "--------------------"
echo " 2. Create frontend secrects"
echo "--------------------"
createFrontendSecrets

echo "--------------------"
echo " 3. Create frontend configmap"
echo "--------------------"
createFrontendConfigMap

echo "--------------------"
echo " 4. Create and apply build"
echo "--------------------"
createAndApplyBuildConfig

echo "--------------------"
echo " 5. Create deployment"
echo "--------------------"
createDeployment

echo "--------------------"
echo " 6. Create service"
echo "--------------------"
createService

echo "--------------------"
echo " 7. Create route"
echo "--------------------"
createRoute