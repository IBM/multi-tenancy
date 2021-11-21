#!/bin/bash

# **************** Global variables
root_folder=$(cd $(dirname $0); cd ../../../; pwd)
# secrets
export APPID_SECRETS_TEMPLATE_FILE="appid-secrets-template.yaml"
export POSTGRES_SECRETS_TEMPLATE_FILE="postgres-secrets-template.yaml"
export APPID_SECRETS_FILE="appid-secrets.yaml"
export POSTGRES_SECRETS_FILE="postgres-secrets.yaml"
# configmap
export FRONTEND_TEMPLATE_FILE="configmap-frontend-template.yaml"
export FRONTEND_FILE="configmap-frontend.yaml"
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
# OpenShift
export OS_PROJECT="multi-tenancy-openshift"
export OS_BUILD="frontend-build"


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
  
  echo "********************"
  echo "Have you created an App ID instance?"
  echo "Copy the credentials in local.env: APPID_CLIENT_ID, APPID_DISCOVERYENDPOINT"
 
  CFG_FILE=${root_folder}/local.env
  
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  echo "local.env exists: $CFG_FILE"
  source $CFG_FILE
  
  echo "-> create app id secrets"
  TMP_FILE_1=tmp_frontend_secrect_1.yaml
  TMP_FILE_2=tmp_frontend_secrect_2.yaml

  KEY_TO_REPLACE=APPID_CLIENT_ID
  sed "s+$KEY_TO_REPLACE+$APPID_CLIENT_ID+g" "${root_folder}/openshift/deployments/secrets/$APPID_SECRETS_TEMPLATE_FILE" > ${root_folder}/openshift/deployments/secrets/$TMP_FILE_1

  KEY_TO_REPLACE=APPID_DISCOVERYENDPOINT
  sed "s+$KEY_TO_REPLACE+$APPID_DISCOVERYENDPOINT+g" "${root_folder}/openshift/deployments/secrets/$TMP_FILE_1" > ${root_folder}/openshift/deployments/secrets/$TMP_FILE_2

  KEY_TO_REPLACE=APPID_AUTH_SERVER_URL
  sed "s+$KEY_TO_REPLACE+$APPID_AUTH_SERVER_URL+g" "${root_folder}/openshift/deployments/secrets/$TMP_FILE_2" > ${root_folder}/openshift/deployments/secrets/$APPID_SECRETS_FILE

  rm -f ${root_folder}/openshift/deployments/secrets/$TMP_FILE_1
  rm -f ${root_folder}/openshift/deployments/secrets/$TMP_FILE_2
}

function createFrontendConfigMap () {
 
  echo "-> create configmap for frontend"
  TMP_FILE_1=tmp_frontend_config_1.yaml
  TMP_FILE_2=tmp_frontend_config_2.yaml

  KEY_TO_REPLACE=URL_PRODUCTS_1
  sed "s+$KEY_TO_REPLACE+$URL_PRODUCTS+g" "${root_folder}/openshift/deployments/configmaps/$FRONTEND_TEMPLATE_FILE" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1

  KEY_TO_REPLACE=URL_ORDERS_1
  sed "s+$KEY_TO_REPLACE+$URL_ORDERS+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2

  KEY_TO_REPLACE=URL_CATEGORIES_1
  sed "s+$KEY_TO_REPLACE+$URL_CATEGORIES+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1

  KEY_TO_REPLACE=APP_CATEGORY_NAME_1
  sed "s+$KEY_TO_REPLACE+$APP_CATEGORY_NAME+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2

  KEY_TO_REPLACE=APP_HEADLINE_1
  sed "s+$KEY_TO_REPLACE+$APP_HEADLINE+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2" > ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1

  KEY_TO_REPLACE=APP_ROOT_1
  sed "s+$KEY_TO_REPLACE+$APP_ROOT+g" "${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1" > ${root_folder}/openshift/deployments/configmaps/$FRONTEND_FILE

  rm -f ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_1
  rm -f ${root_folder}/openshift/deployments/configmaps/$TMP_FILE_2
}

function createAndApplyBuildConfig () {
  
  echo "-> create build config"
  TMP_FILE_1=tmp_build-config_1.yaml
  TMP_FILE_2=tmp_build-config_2.yaml

  KEY_TO_REPLACE=GIT_REPO_1
  sed "s+$KEY_TO_REPLACE+$GIT_REPO+g" "${root_folder}/openshift/deployments/build-configuration/$FRONTEND_TEMPLATE_BUILD_CONFIG_FILE" > ${root_folder}/openshift/deployments/build-configuration/$FRONTEND_BUILD_CONFIG_FILE
  echo "delete build config"
  oc delete build $OS_BUILD
  echo "create build config"
  oc apply -f "${root_folder}/openshift/deployments/build-configuration/$FRONTEND_BUILD_CONFIG_FILE"
  echo "verify build config"
  oc describe bc/$OS_BUILD
  echo "start build"
  oc start-build $OS_BUILD
  echo "verify build logs"
  oc logs -f bc/$OS_BUILD
  
  rm -f ${root_folder}/openshift/deployments/build-config/$TMP_FILE_1
  rm -f ${root_folder}/openshift/deployments/build-config/$TMP_FILE_2
}

function createProject () {
  echo "-> delete project"
  oc delete project "$OS_PROJECT"
  echo "-> create project"
  oc new-project "$OS_PROJECT"
}

# **********************************************************************************
# Execution
# **********************************************************************************

createProject

createFrontendSecrets

createFrontendConfigMap

createAndApplyBuildConfig