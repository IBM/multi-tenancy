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

# ecommerce application container registry image quay
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

function createNamespace(){
     
    echo "IBMCLOUD_CR_NAMESPACE: $IBMCLOUD_CR_NAMESPACE"
    ibmcloud cr login
    ibmcloud cr namespace-add $IBMCLOUD_CR_NAMESPACE
}

function createAndPushIBMContainer () {

    createNamespace
    FRONTEND_IMAGE="$IBMCLOUD_CR_REGION_URL/$IBMCLOUD_CR_NAMESPACE/$IBMCLOUD_CR_FRONTEND:$IBMCLOUD_CR_TAG"
    SERVICE_CATALOG_IMAGE="$IBMCLOUD_CR_REGION_URL/$IBMCLOUD_CR_NAMESPACE/$IBMCLOUD_CR_FRONTEND:$IBMCLOUD_CR_TAG"
    
    echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"
    echo "SERVICE_CATALOG_IMAGE: $SERVICE_CATALOG_IMAGE"
    bash ./ce-build-images-ibm-docker.sh $SERVICE_CATALOG_IMAGE \
                                         $FRONTEND_IMAGE

}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Create and push container image to Quay registry"
echo "************************************"

# createAndPushQuayContainer

echo "************************************"
echo " Create and push container image to IBM Container Registry"
echo "************************************"

createAndPushIBMContainer

echo "************************************"
echo " Tenant A"
echo "************************************"

#bash ./ce-install-application.sh $TENANT_A

# echo "************************************"
# echo " Tenant B"
# echo "************************************"

# bash ./ce-install-application.sh $TENANT_B