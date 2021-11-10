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

# Using tenant a to define:
# ecommerce application name
export FRONTEND_NAME=$(cat ./$TENANT_A | jq '.[].container_images.FRONTEND_NAME' | sed 's/"//g')
export SERVICE_CATALOG_NAME=$(cat ./$TENANT_A | jq '.[].container_images.SERVICE_CATALOG_NAME' | sed 's/"//g')
# ecommerce application container name
export FRONTEND_IMAGE=$(cat ./$TENANT_A | jq '.[].container_images.FRONTEND_IMAGE' | sed 's/"//g')
export SERVICE_CATALOG_IMAGE=$(cat ./$TENANT_A | jq '.[].container_images.SERVICE_CATALOG_IMAGE' | sed 's/"//g')

# Registry settings
# ibm cloud  container registry settings
export IBMCLOUD_CR_NAMESPACE=$(cat ./$TENANT_A | jq '.[].container_ibmregistry.IBMCLOUD_CR_NAMESPACE' | sed 's/"//g')
export IBMCLOUD_CR_REGION_URL=$(cat ./$TENANT_A | jq '.[].container_ibmregistry.IBMCLOUD_CR_REGION_URL' | sed 's/"//g')
export IBMCLOUD_CR_TAG=$(cat ./$TENANT_A | jq '.[].container_ibmregistry.IBMCLOUD_CR_TAG' | sed 's/"//g')

# quay container registry settings
export QUAY_CR_PROJECT=$(cat ./$TENANT_A | jq '.[].container_quayregistry.QUAY_CR_PROJECT' | sed 's/"//g')
export QUAY_URL=$(cat ./$TENANT_A | jq '.[].container_quayregistry.QUAY_URL' | sed 's/"//g')
export QUAY_CR_TAG=$(cat ./$TENANT_A | jq '.[].container_quayregistry.QUAY_CR_TAG' | sed 's/"//g')

# **********************************************************************************
# Functions definition
# **********************************************************************************

function createAndPushQuayContainer () {
    
    echo "Build image names"
    FRONTEND_IMAGE="$QUAY_URL/$IQUAY_CR_PROJECT/$FRONTEND_NAME:$QUAY_CR_TAG"
    SERVICE_CATALOG_IMAGE="$QUAY_URL/$QUAY_CR_PROJECT/$SERVICE_CATALOG_NAME:$QUAY_CR_TAG"
    
    echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"
    echo "SERVICE_CATALOG_IMAGE: $SERVICE_CATALOG_IMAGE"
    
    RESULT=$(cat ./$TENANT_A | jq --arg service_catalog "$SERVICE_CATALOG_IMAGE" '.[].container_images.SERVICE_CATALOG_IMAGE |= $service_catalog')
    echo "$RESULT" > ./$TENANT_A 
    RESULT=$(cat ./$TENANT_A | jq --arg frontend "$FRONTEND_IMAGE" '.[].container_images.FRONTEND_IMAGE |= $frontend')
    echo "$RESULT" > ./$TENANT_A

    echo "Update configuration file ./$TENANT_A "
    RESULT=$(cat ./$TENANT_B | jq --arg service_catalog "$SERVICE_CATALOG_IMAGE" '.[].container_images.SERVICE_CATALOG_IMAGE |= $service_catalog')
    echo "$RESULT" > ./$TENANT_B 
    RESULT=$(cat ./$TENANT_A | jq --arg frontend "$FRONTEND_IMAGE" '.[].container_images.FRONTEND_IMAGE |= $frontend')
    echo "$RESULT" > ./$TENANT_B

    bash ./ce-build-images-quay-docker.sh $SERVICE_CATALOG_IMAGE \
                                          $FRONTEND_IMAGE

}

function createNamespace(){
     
    echo "IBMCLOUD_CR_NAMESPACE: $IBMCLOUD_CR_NAMESPACE"
    ibmcloud cr login
    ibmcloud cr namespace-add $IBMCLOUD_CR_NAMESPACE

}

function createAndPushIBMContainer () {

    echo "Build image names" 
    FRONTEND_IMAGE="$IBMCLOUD_CR_REGION_URL/$IBMCLOUD_CR_NAMESPACE/$FRONTEND_NAME:$IBMCLOUD_CR_TAG"
    SERVICE_CATALOG_IMAGE="$IBMCLOUD_CR_REGION_URL/$IBMCLOUD_CR_NAMESPACE/$SERVICE_CATALOG_NAME:$IBMCLOUD_CR_TAG"
    
    echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"
    echo "SERVICE_CATALOG_IMAGE: $SERVICE_CATALOG_IMAGE"

    echo "Update configuration files ./$TENANT_A and ./$TENANT_B "

    RESULT=$(cat ./$TENANT_A | jq --arg service_catalog "$SERVICE_CATALOG_IMAGE" '.[].container_images.SERVICE_CATALOG_IMAGE |= $service_catalog')
    echo "$RESULT" > ./$TENANT_A 
    RESULT=$(cat ./$TENANT_A | jq --arg frontend "$FRONTEND_IMAGE" '.[].container_images.FRONTEND_IMAGE |= $frontend')
    echo "$RESULT" > ./$TENANT_A

    RESULT=$(cat ./$TENANT_B | jq --arg service_catalog "$SERVICE_CATALOG_IMAGE" '.[].container_images.SERVICE_CATALOG_IMAGE |= $service_catalog')
    echo "$RESULT" > ./$TENANT_B 
    RESULT=$(cat ./$TENANT_A | jq --arg frontend "$FRONTEND_IMAGE" '.[].container_images.FRONTEND_IMAGE |= $frontend')
    echo "$RESULT" > ./$TENANT_B

    createNamespace
    
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

#echo "************************************"
#echo " Tenant A"
#echo "************************************"

#bash ./ce-install-application.sh $TENANT_A

echo "************************************"
echo " Tenant B"
echo "************************************"

bash ./ce-install-application.sh $TENANT_B