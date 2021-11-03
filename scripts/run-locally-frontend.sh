#!/bin/bash

# **************** Global variables set by parameters
pwd
root_folder=$(cd $(dirname $0); cd ..; pwd)
cd "$root_folder"
vue_env_config=./code/frontend/public/env-config.js
vue_env_config_template=./scripts/env-config-template.js

# change the standard output
exec 3>&1

# **********************************************************************************
# Functions definition
# **********************************************************************************

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() { 

  echo "Have you created an App ID instance?"
  echo "Copy the credentials in local.env: APPID_CLIENT_ID, APPID_DISCOVERYENDPOINT"
 
  CFG_FILE=${root_folder}/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi

  source $CFG_FILE
  
  echo "Creating App ID configuration $vue-env-config"
  echo " - $APPID_CLIENT_ID"
  echo " - $APPID_DISCOVERYENDPOINT"

  cd ${root_folder}
  sed -e "s+APPID_CLIENT_ID_TEMPLATE+${APPID_CLIENT_ID}+g" \
      -e "s+APPID_DISCOVERYENDPOINT_TEMPLATE+${APPID_DISCOVERYENDPOINT}+g" \
      "${vue_env_config_template}" > "${vue_env_config}"

  echo "Starting frontend locally ..."
  cd ${root_folder}/code/frontend
  npm install
  npm run serve
}

# **********************************************************************************
# Execution
# **********************************************************************************

triggerScript