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

# ibm cloud  container registry settings
export IBMCLOUD_CR_NAMESPACE=multi-tenancy-example
export IBMCLOUD_CR_REGION_URL=us.icr.io
export IBMCLOUD_CR_FRONTEND=frontend
export IBMCLOUD_CR_SERVICE_CATALOG=service-catalog
export IBMCLOUD_CR_TAG=v1

# **********************************************************************************
# Functions definition
# **********************************************************************************

function createAndPushQuayContainer () {
    bash ./ce-build-images-quay-docker.sh $SERVICE_CATALOG_IMAGE \
                                          $FRONTEND_IMAGE

}

function createAndPushIBMContainer () {

    createNamespace
    FRONTEND_IMAGE="$IBMCLOUD_CR_REGION_URL/$IBMCLOUD_CONTAINER_NAMESPACE/$IBMCLOUD_CR_FRONTEND:$IBMCLOUD_CR_TAG"
    SERVICE_CATALOG_IMAGE="$IBMCLOUD_CR_REGION_URL/$IBMCLOUD_CONTAINER_NAMESPACE/$IBMCLOUD_CR_FRONTEND:$IBMCLOUD_CR_TAG"
    bash ./ce-build-images-ibm-docker.sh $SERVICE_CATALOG_IMAGE \
                                         $FRONTEND_IMAGE

}

function createNamespace(){
    ibmcloud cr login
    ibmcloud cr namespace-add $IBMCLOUD_CONTAINER_NAMESPACE
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Create container in Quay registry"
echo "************************************"

# createAndPushQuayContainer
# createAndPushIBMContainer

echo "************************************"
echo " Tenant A"
echo "************************************"

bash ./ce-install-application.sh $TENANT_A

# echo "************************************"
# echo " Tenant B"
# echo "************************************"

# bash ./ce-install-application.sh $TENANT_B