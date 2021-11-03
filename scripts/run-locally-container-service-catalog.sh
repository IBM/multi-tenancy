#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function triggerScript() { 

  echo "You need to create a Postgres database first"
  echo "You need to have podman installed locally first"
  echo "Copy the credentials in local.env: POSTGRES_USERNAME, POSTGRES_PASSWORD, POSTGRES_URL"

  cd ${root_folder}
  CFG_FILE=${root_folder}/local.env
  if [ ! -f $CFG_FILE ]; then
    _out Config file local.env is missing!
    exit 1
  fi
  set -o allexport
  source $CFG_FILE
  cat $CFG_FILE

  cd ${root_folder}/code/service-catalog
  
  podman container stop service-catalog
  podman container rm -f service-catalog
  podman image rm -f service-catalog
  podman build  --file Dockerfile \
                --tag service-catalog

#  docker run --name=service-catalog \
#    -it \
#    --env default_datasource_certs=${default_datasource_base_certs} \
#    --env default_datasource_certs_data=${default_datasource_certs_data} \
#    -p 8080:8080/tcp \
#    "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"    

  echo "Starting catalog service locally in a container"
  echo curl  \"http://localhost:8081/category\"
  echo curl  \"http://localhost:8081/category/2/products\"
}

triggerScript