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
   echo "************************************"
   cd ../../
   export ROOT_PATH=$(PWD)
   echo "Path: $ROOT_PATH"
}

function resetPath() {
   echo "************************************"
   echo " Reset path"
   echo "************************************"
   cd $ROOT_PATH/$ROOT_PROJECT/scripts
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
  echo "Starting backend service locally in a container ..."
  echo curl  \"http://localhost:8081/category\"
  echo curl  \"http://localhost:8081/category/2/products\"
  echo "/category will return a response code '401' not authorized!"
  echo "/category/2/products will return data from Postgres"

  cd ${ROOT_PATH}/$BACKEND_SOURCEFOLDER
  CFG_FILE=${ROOT_PATH}/$ROOT_PROJECT/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi

  set -o allexport
  source $CFG_FILE

  POSTGRES_URL=$(echo $POSTGRES_URL| cut -d'?' -f 1)
  CERTIFICATE_PATH=/cloud-postgres-cert
  POSTGRES_URL="$POSTGRES_URL?sslmode=verify-full&sslrootcert=$CERTIFICATE_PATH"
  APPID_AUTH_SERVER_URL=${APPID_AUTH_SERVER_URL}
  APPID_CLIENT_ID=${APPID_CLIENT_ID}

  POSTGRES_CERTIFICATE_DATA=$(<$ROOT_PATH/$BACKEND_SOURCEFOLDER/src/main/resources/certificates/${POSTGRES_CERTIFICATE_FILE_NAME})

  cd ${root_folder}/../multi-tenancy-backend
  podman container stop service-catalog --ignore
  podman container rm -f service-catalog --ignore
  podman build --file Dockerfile --tag service-catalog

  podman run --name=service-catalog \
    -it \
    -e POSTGRES_CERTIFICATE_DATA="${POSTGRES_CERTIFICATE_DATA}" \
    -e POSTGRES_USERNAME="${POSTGRES_USERNAME}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_URL="${POSTGRES_URL}" \
    -e APPID_AUTH_SERVER_URL="${APPID_AUTH_SERVER_URL}" \
    -e APPID_CLIENT_ID="${APPID_CLIENT_ID}" \
    -p 8081:8081/tcp \
    localhost/service-catalog:latest
}

# **********************************************************************************
# Execution
# **********************************************************************************

setROOT_PATH
triggerScript
resetPath