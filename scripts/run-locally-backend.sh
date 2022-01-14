#!/bin/bash

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
   cd $ROOT_PATH/$ROOT_PROJECT
   echo ""
}

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() {

  echo "1. Have you created an App ID instance?"
  echo "Copy the credentials in local.env: APPID_CLIENT_ID, APPID_AUTH_SERVER_URL"
  echo ""
  echo "2. Have you created a Postgres instance?"
  echo "Copy the credentials in local.env: POSTGRES_USERNAME, POSTGRES_PASSWORD, POSTGRES_URL, POSTGRES_CERTIFICATE_FILE_NAME"
  echo "Copy the Postgres certificate in multi-tenancy-backend/src/main/resources/certificates"
  echo "Starting backend service locally ..."
  echo curl  \"http://localhost:8081/category\"
  echo curl  \"http://localhost:8081/category/2/products\"
  echo "/category will return a response code '401' not authorized!"
  echo "/category/2/products will return data from Postgres"

  cd $ROOT_PATH/$BACKEND_SOURCEFOLDER
  CFG_FILE=$ROOT_PATH/$ROOT_PROJECT/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  
  set -o allexport
  source $CFG_FILE
   
  APPID_AUTH_SERVER_URL=${APPID_AUTH_SERVER_URL}
  APPID_CLIENT_ID=${APPID_CLIENT_ID}

  POSTGRES_URL=$(echo $POSTGRES_URL| cut -d'?' -f 1)
  CERTIFICATE_PATH=$ROOT_PATH/$BACKEND_SOURCEFOLDER/src/main/resources/certificates/cloud-postgres-cert
  cp $ROOT_PATH/$BACKEND_SOURCEFOLDER/src/main/resources/certificates/$POSTGRES_CERTIFICATE_FILE_NAME $CERTIFICATE_PATH
  POSTGRES_URL="$POSTGRES_URL?sslmode=verify-full&sslrootcert=$CERTIFICATE_PATH"

  cd $ROOT_PATH/$BACKEND_SOURCEFOLDER
  mvn clean package
  mvn quarkus:dev
}

# **********************************************************************************
# Execution
# **********************************************************************************

setROOT_PATH
triggerScript
resetPath