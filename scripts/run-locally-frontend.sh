#!/bin/bash

# **************** Global variables set by parameters
ROOT_PROJECT=multi-tenancy
FRONTEND_SOURCEFOLDER=multi-tenancy-frontend
BACKEND_SOURCEFOLDER=multi-tenancy-backend

# change the standard output
exec 3>&1

# **********************************************************************************
# Functions definition
# **********************************************************************************

function setROOT_PATH() {
   echo "************************************"
   echo " Set ROOT_PATH"
   echo " REMEMBER: You must start the script from the project root folder as written in the documentation!"
   echo "************************************"
   cd ../
   export ROOT_PATH=$(PWD)
   echo "Path: $ROOT_PATH"
}

function resetPath() {
   echo "************************************"
   echo " Reset path"
   echo "************************************"
   cd $ROOT_PATH/$ROOT_PROJECT/
   echo ""
}

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() { 

  vue_env_config=$ROOT_PATH/$FRONTEND_SOURCEFOLDER/public/env-config.js
  vue_env_config_template=$ROOT_PATH/$ROOT_PROJECT/scripts/env-config-template.js

  echo "Have you created an App ID instance?"
  echo "Copy the credentials in local.env: APPID_CLIENT_ID, APPID_DISCOVERYENDPOINT"
 
  CFG_FILE=$ROOT_PATH/$ROOT_PROJECT/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi

  source $CFG_FILE
  
  echo "Creating App ID configuration $vue-env-config"
  echo " - $APPID_CLIENT_ID"
  echo " - $APPID_DISCOVERYENDPOINT"

  cd $ROOT_PATH/$FRONTEND_SOURCEFOLDER
  sed -e "s+APPID_CLIENT_ID_TEMPLATE+${APPID_CLIENT_ID}+g" \
      -e "s+APPID_DISCOVERYENDPOINT_TEMPLATE+${APPID_DISCOVERYENDPOINT}+g" \
      "${vue_env_config_template}" > "${vue_env_config}"

  echo "Starting frontend locally ..."
  cd $ROOT_PATH/$FRONTEND_SOURCEFOLDER
  npm install
  npm run serve
}

# **********************************************************************************
# Execution
# **********************************************************************************

setROOT_PATH
triggerScript
resetPath