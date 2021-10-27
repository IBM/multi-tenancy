#!/bin/bash

# **** Global variables

export REGISTRY=localmachine
export IMAGE_NAME=service_catalog_local
export IMAGE_TAG=v1

# default
export default_datasource_base_certs="5df929c2-b76a-11e9-b3dd-4acf6c229d45"
export default_datasource_mycompany_certs="2b11af40-8aa6-4b13-a424-1a9109624264"

# **********************************************************************************
# Execution
# **********************************************************************************

# Show output
set -x

# Set the right directory
cd ../code/service-catalog-tmp

# Build the image
docker container stop -f  "service-catalog-verification"
docker container rm -f "service-catalog-verification"
docker image rm -f "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
docker build  --file Dockerfile \
              --tag "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG" .

# Run the container
docker run --name="service-catalog-verification" \
           -it \
           --env default_datasource_certs=${default_datasource_base_certs} \
           --env default_datasource_certs_data=${default_datasource_certs_data} \
           -p 8080:8080/tcp \
           "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
                           

