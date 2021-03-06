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

# IBM Cloud target
export RESOURCE_GROUP=$(cat ./$GLOBAL | jq '.IBM_CLOUD.RESOURCE_GROUP' | sed 's/"//g')
export REGION=$(cat ./$GLOBAL | jq '.IBM_CLOUD.REGION' | sed 's/"//g')

# **********************************************************************************
# Functions definition
# **********************************************************************************
# FYI: https://stackoverflow.com/questions/12468889/bash-script-error-function-not-found-why-would-this-appear

createNamespaceBuildah() {
     
    echo "IBMCLOUD_CR_NAMESPACE: $IBMCLOUD_CR_NAMESPACE"
    echo "RESOURCE_GROUP       : $RESOURCE_GROUP"
    echo "REGION               : $REGION"
    echo "------------------------------"
    echo "Verify the given entries and press return"
    
    read input

    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    ibmcloud target
    # login with buildah
    ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $IBMCLOUD_CR_REGION_URL
    RESULT=$(ibmcloud cr namespace-add $IBMCLOUD_CR_NAMESPACE | grep "FAILED")

    if [[ $RESULT =~ "FAILED"  ]]; then
       echo "*** Namespace $IBMCLOUD_CR_NAMESPACE in IBM Cloud Container Registry NOT created !"
       echo "*** The scripts ends here!"
       echo "*** Please define a different namespace name in the 'configuration/global.json' file."
       exit 1
    else 
       echo "- Namespace $IBMCLOUD_CR_NAMESPACE in IBM Cloud Container Registry created !"
    fi

}

createAndPushIBMContainer () {
 
    echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"
    echo "SERVICE_CATALOG_IMAGE: $SERVICE_CATALOG_IMAGE"
    echo "IBMCLOUD_CR_REGION_URL: $IBMCLOUD_CR_REGION_URL"

    createNamespaceBuildah
    
    bash ./ce-build-images-ibm-buildah.sh $SERVICE_CATALOG_IMAGE $FRONTEND_IMAGE 
    
    if [ $? == "1" ]; then
      echo "*** Creation of the container images failed !"
      echo "*** The script 'ce-create-two-tenancies.sh' ends here!"
      exit 1
    fi
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " Create and push container image to IBM Container Registry"
echo "************************************"

createAndPushIBMContainer

echo "************************************"
echo " Tenant A"
echo "************************************"

bash ./ce-install-application.sh $GLOBAL $TENANT_A

if [ $? == "1" ]; then
  echo "*** The installation for '$GLOBAL' '$TENANT_A' configuation failed !"
  echo "*** The script 'ce-create-two-tenancies.sh' ends here!"
  exit 1
fi

echo "************************************"
echo " Tenant B"
echo "************************************"

bash ./ce-install-application.sh $GLOBAL $TENANT_B

if [ $? == "1" ]; then
  echo "*** The installation for '$GLOBAL' '$TENANT_B' configuation failed !"
  echo "*** The script 'ce-create-two-tenancies.sh' ends here!"
  exit 1
fi