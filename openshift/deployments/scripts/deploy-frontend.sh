#!/bin/bash

# **************** Global variables
root_folder=$(cd $(dirname $0); cd ../../../; pwd)
APPID_SECRETS_TEMPLATE_FILE="appid-secrets-template.yaml"
POSTGRES_SECRETS_TEMPLATE_FILE="postgres-secrets-template.yaml"
APPID_SECRETS_FILE="appid-secrets.yaml"
POSTGRES_SECRETS_FILE="postgres-secrets.yaml"

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


# **********************************************************************************
# Execution
# **********************************************************************************

createFrontendSecrets