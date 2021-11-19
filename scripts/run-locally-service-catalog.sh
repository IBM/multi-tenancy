#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() {

  echo "1. Have you created an App ID instance?"
  echo "Copy the credentials in local.env: APPID_CLIENT_ID, APPID_AUTH_SERVER_URL"
  echo ""
  echo "2. Have you created a Postgres instance?"
  echo "Copy the credentials in local.env: POSTGRES_USERNAME, POSTGRES_PASSWORD, POSTGRES_URL, POSTGRES_CERTIFICATE_FILE_NAME"
  echo "Copy the Postgres certificate in code/service-catalog/src/main/resources/certificates"
  echo "Starting catalog service locally ..."
  echo curl  \"http://localhost:8081/category\"
  echo curl  \"http://localhost:8081/category/2/products\"
  echo "... both curl's will return with response code '401' not authorized!"

  CFG_FILE=${root_folder}/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  
  set -o allexport
  source $CFG_FILE
   
  APPID_AUTH_SERVER_URL=${APPID_AUTH_SERVER_URL}
  APPID_CLIENT_ID=${APPID_CLIENT_ID}

  POSTGRES_URL=$(echo $POSTGRES_URL| cut -d'?' -f 1)
  CERTIFICATE_PATH=${root_folder}/code/service-catalog/src/main/resources/certificates/cloud-postgres-cert
  cp ${root_folder}/code/service-catalog/src/main/resources/certificates/$POSTGRES_CERTIFICATE_FILE_NAME $CERTIFICATE_PATH
  POSTGRES_URL="$POSTGRES_URL?sslmode=verify-full&sslrootcert=$CERTIFICATE_PATH"

  cd ${root_folder}/code/service-catalog
  mvn clean package
  mvn quarkus:dev
}

triggerScript