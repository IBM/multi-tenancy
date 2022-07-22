#!/bin/bash
# CLI Documentation
# ================
# command documentation: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create

# Install jq to extract json in bash on mac
# ===============
# brew install jq

# **************** Global variables

# Configurations
export GLOBAL="../configuration/global.json"
export TENANT_A="../configuration/tenants/tenant-a.json"
export TENANT_B="../configuration/tenants/tenant-b.json"

# ecommerce application container image names
export REGISTRY_URL=$(cat ./$GLOBAL | jq '.REGISTRY.URL' | sed 's/"//g')
export IMAGE_TAG=$(cat ./$GLOBAL | jq '.REGISTRY.TAG' | sed 's/"//g')
export NAMESPACE=$(cat ./$GLOBAL | jq '.REGISTRY.NAMESPACE' | sed 's/"//g')
export FRONTEND_IMAGE_NAME=$(cat ./$GLOBAL | jq '.IMAGES.NAME_FRONTEND' | sed 's/"//g')
export BACKEND_IMAGE_NAME=$(cat ./$GLOBAL | jq '.IMAGES.NAME_BACKEND' | sed 's/"//g')
export FRONTEND_IMAGE="$REGISTRY_URL/$NAMESPACE/$FRONTEND_IMAGE_NAME:$IMAGE_TAG"
export SERVICE_CATALOG_IMAGE="$REGISTRY_URL/$NAMESPACE/$BACKEND_IMAGE_NAME:$IMAGE_TAG"

# Registry settings
# ibm cloud  container registry settings
export IBMCLOUD_CR_NAMESPACE=$(cat ./$GLOBAL | jq '.REGISTRY.NAMESPACE' | sed 's/"//g')
export IBMCLOUD_CR_REGION_URL=$(cat ./$GLOBAL | jq '.REGISTRY.URL' | sed 's/"//g')
export IBMCLOUD_CR_TAG=$(cat ./$GLOBAL | jq '.REGISTRY.TAG' | sed 's/"//g')
export IBMCLOUD_CR_SECRET_NAME=$(cat ./$GLOBAL | jq -r '.REGISTRY.SECRET_NAME' | sed 's/"//g')

# IBM Cloud target
export RESOURCE_GROUP=$(cat ./$GLOBAL | jq -r '.IBM_CLOUD.RESOURCE_GROUP')
export REGION=$(cat ./$GLOBAL | jq -r '.IBM_CLOUD.REGION')
# Code Engine
export IBMCLOUD_CE_BUILD_PROJECT=$(cat ./$TENANT_A | jq -r '.CODE_ENGINE.PROJECT_NAME') 

# **********************************************************************************
# Functions definition
# **********************************************************************************
# FYI: https://stackoverflow.com/questions/12468889/bash-script-error-function-not-found-why-would-this-appear

configLogin() {
     
    echo "IBMCLOUD_CR_NAMESPACE: $IBMCLOUD_CR_NAMESPACE"
    echo "RESOURCE_GROUP       : $RESOURCE_GROUP"
    echo "REGION               : $REGION"
    echo "------------------------------"
    echo "Verify the given entries and press return"
    
    read input

    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    ibmcloud target

}

createIBMContainer () {
 
    echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"
    echo "SERVICE_CATALOG_IMAGE: $SERVICE_CATALOG_IMAGE"
    echo "IBMCLOUD_CR_REGION_URL: $IBMCLOUD_CR_REGION_URL"
    echo "IBMCLOUD_CE_BUILD_PROJECT: $IBMCLOUD_CE_BUILD_PROJECT"

    # createNamespaceBuildah
    
    bash ./tz-build-images-code-engine.sh $SERVICE_CATALOG_IMAGE $FRONTEND_IMAGE $IBMCLOUD_CR_REGION_URL \
                                          $IBMCLOUD_CE_BUILD_PROJECT $IBMCLOUD_CR_SECRET_NAME
    
    if [ $? == "1" ]; then
      echo "*** Creation of the container images failed !"
      echo "*** The script 'tz-create-two-tenancies.sh' ends here!"
      exit 1
    fi
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Create container image in IBM Container Registry"
echo "************************************"

configLogin
createIBMContainer

echo "************************************"
echo " Tenant A"
echo "************************************"

bash ./tz-install-application.sh $GLOBAL $TENANT_A skip-cr-secret

if [ $? == "1" ]; then
  echo "*** The installation for '$GLOBAL' '$TENANT_A' configuation failed !"
  echo "*** The script 'tz-create-two-tenancies.sh' ends here!"
  exit 1
fi

echo "************************************"
echo " Tenant B"
echo "************************************"

bash ./tz-install-application.sh $GLOBAL $TENANT_B

if [ $? == "1" ]; then
  echo "*** The installation for '$GLOBAL' '$TENANT_B' configuation failed !"
  echo "*** The script 'tz-create-two-tenancies.sh' ends here!"
  exit 1
fi