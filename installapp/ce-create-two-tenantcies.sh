#!/bin/bash

# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# Install jq to extract json in bash on mac
# ===============
# brew install jq

# **************** Global variables

# Tenancies
export TENANT_A="tenant-a-parameters.json"
export TENANT_B="tenant-b-parameters.json"

# ecommerce application container registry
export FRONTEND_IMAGE=$(cat ./tenant-a-parameters.json | jq '.[].container_images.FRONTEND_IMAGE' | sed 's/"//g')
export SERVICE_CATALOG_IMAGE=$(cat ./tenant-a-parameters.json | jq '.[].container_images.SERVICE_CATALOG_IMAGE' | sed 's/"//g')

# **********************************************************************************
# Functions definition
# **********************************************************************************

function createAndPushQuayContainer () {
    bash ./ce-build-images-quay-docker.sh $SERVICE_CATALOG_IMAGE \
                                          $FRONTEND_IMAGE

}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Create container in Quay registry"
echo "************************************"

# createAndPushQuayContainer

echo "************************************"
echo " Tenant A"
echo "************************************"

bash ./ce-install-application.sh $TENANT_A

# echo "************************************"
# echo " Tenant B"
# echo "************************************"

# bash ./ce-install-application.sh $TENANT_B