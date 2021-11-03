#!/bin/bash

# **************** Global variables set by parameters
root_folder=$(cd $(dirname $0); cd ..; pwd)
cd "$root_folder"
vue_env_config=./code/frontend/public/env-config.js
vue_env_config_template=./scripts/env-config-template.js
service_catalog_categories_endpoint="http://localhost:8081/category"
service_catalog_product_endpoint="http://localhost:8081/category"

# change the standard output
exec 3>&1

# **********************************************************************************
# Functions definition
# **********************************************************************************

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() { 
  
  echo "********************"
  echo "Have you created an App ID instance?"
  echo "Copy the credentials in local.env: APPID_CLIENT_ID, APPID_DISCOVERYENDPOINT"
 
  CFG_FILE=${root_folder}/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  source $CFG_FILE

  cd ${root_folder}/code/frontend
  echo "********************"
  echo "Clean-up container and image"
  podman container stop frontend-container --ignore
  podman container rm -f frontend-container --ignore
  podman image rm -f 'frontend:v1'
  
  echo "********************"
  echo "Build container"
  podman build --file Dockerfile.os4-webapp --tag 'frontend:v1'
  
  echo "********************"
  echo "Starting container with App ID configuration"
  echo " - $APPID_CLIENT_ID"
  echo " - $APPID_DISCOVERYENDPOINT"

  podman run --name=frontend-container \
    -it \
    -e VUE_APPID_CLIENT_ID=$APPID_CLIENT_ID \
    -e VUE_APPID_DISCOVERYENDPOINT=$APPID_DISCOVERYENDPOINT \
    -e VUE_APP_API_URL_PRODUCTS="${service_catalog_product_endpoint}" \
    -e VUE_APP_API_URL_CATEGORIES="${service_catalog_product_endpoint}" \
    -e VUE_APP_CATEGORY_NAME='Movies' \
    -e VUE_APP_HEADLINE='Frontend Docker' \
    -p 8080:8080/tcp \
    "localhost/frontend:v1"
}

# **********************************************************************************
# Execution
# **********************************************************************************

triggerScript