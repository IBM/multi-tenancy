#!/bin/bash

# CLI tools Documentation
# ================
# Code Engine: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create
# Cloud databases
# IBM Cloud Container Registry 

# Needed IBM Cloud CLI plugins
# =============
# - code engine 
# - cloud databases (ibmcloud plugin install cloud-databases)
# - container registry 

# Needed tools 
# ============
# For Postgres database
# - brew install libpq
# - brew link --force libpq
# Install jq to extract json in bash on mac
# - brew install jq

echo "************************************"
echo " Display parameter"
echo "************************************"
echo ""
echo "Parameter count : $@"
echo "Parameter zero 'name of the script': $0"
echo "---------------------------------"
echo "Global configuration         : $1"
echo "Tenant configuration         : $2"
echo "---------------------------------"

# **************** Global variables set by parameters

# Globale config
# --------------
# IBM Cloud Container Registry
export IBM_CR_SERVER=$(cat ./$1 | jq '.REGISTRY.URL' | sed 's/"//g')
# CE for IBM Cloud Container Registry access
export SECRET_NAME=$(cat ./$1 | jq '.REGISTRY.SECRET_NAME' | sed 's/"//g')
export IBMCLOUDCLI_KEY_NAME="cliapikey_for_multi_tenant_$PROJECT_NAME"
export REGISTRY_URL=$(cat ./$1 | jq '.REGISTRY.URL' | sed 's/"//g')
export IBM_CR_SERVER=$REGISTRY_URL
export IMAGE_TAG=$(cat ./$1 | jq '.REGISTRY.TAG' | sed 's/"//g')
export CR_NAMESPACE=$(cat ./$1 | jq '.REGISTRY.NAMESPACE' | sed 's/"//g')
# IBM Cloud target
export RESOURCE_GROUP=$(cat ./$1 | jq '.IBM_CLOUD.RESOURCE_GROUP' | sed 's/"//g')
export REGION=$(cat ./$1 | jq '.IBM_CLOUD.REGION' | sed 's/"//g')
# ecommerce application container registry
export FRONTEND_IMAGE_NAME=$(cat ./$1 | jq '.IMAGES.NAME_FRONTEND' | sed 's/"//g')
export BACKEND_IMAGE_NAME=$(cat ./$1 | jq '.IMAGES.NAME_BACKEND' | sed 's/"//g')
export FRONTEND_IMAGE="$REGISTRY_URL/$CR_NAMESPACE/$FRONTEND_IMAGE_NAME:$IMAGE_TAG"
export SERVICE_CATALOG_IMAGE="$REGISTRY_URL/$CR_NAMESPACE/$BACKEND_IMAGE_NAME:$IMAGE_TAG"

# Tenant config
# --------------
# Code Engine
export PROJECT_NAME=$(cat ./$2 | jq '.CODE_ENGINE.PROJECT_NAME' | sed 's/"//g') 
# postgres
export POSTGRES_SERVICE_INSTANCE=$(cat ./$2 | jq '.POSTGRES.SERVICE_INSTANCE' | sed 's/"//g') 
export POSTGRES_SERVICE_KEY_NAME=$(cat ./$2 | jq '.POSTGRES.SERVICE_KEY_NAME' | sed 's/"//g')
export POSTGRES_SQL_FILE=$(cat ./$2 | jq '.POSTGRES.SQL_FILE' | sed 's/"//g')
# ecommerce application names
export SERVICE_CATALOG_NAME=$(cat ./$2 | jq '.APPLICATION.CONTAINER_NAME_BACKEND' | sed 's/"//g')
export FRONTEND_NAME=$(cat ./$2 | jq '.APPLICATION.CONTAINER_NAME_FRONTEND' | sed 's/"//g')
export FRONTEND_CATEGORY=$(cat ./$2 | jq '.APPLICATION.CATEGORY' | sed 's/"//g')
# App ID
export APPID_SERVICE_INSTANCE_NAME=$(cat ./$2 | jq '.APP_ID.SERVICE_INSTANCE' | sed 's/"//g')
export APPID_SERVICE_KEY_NAME=$(cat ./$2 | jq '.APP_ID.SERVICE_KEY_NAME' | sed 's/"//g')
export IBMCLOUDCLI_KEY_NAME="cliapikey_for_multi_tenant_$PROJECT_NAME"

echo "Code Engine project              : $PROJECT_NAME"
echo "---------------------------------"
echo "App ID service instance name     : $APPID_SERVICE_INSTANCE_NAME"
echo "App ID service key name          : $APPID_SERVICE_KEY_NAME"
echo "---------------------------------"
echo "Application Service Catalog name : $SERVICE_CATALOG_NAME"
echo "Application Frontend name        : $FRONTEND_NAME"
echo "Application Frontend category    : $FRONTEND_CATEGORY"
echo "Application Service Catalog image: $SERVICE_CATALOG_IMAGE"
echo "Application Frontend image       : $FRONTEND_IMAGE"
echo "---------------------------------"
echo "Postgres instance name           : $POSTGRES_SERVICE_INSTANCE"
echo "Postgres service key name        : $POSTGRES_SERVICE_KEY_NAME"
echo "Postgres sample data sql         : $POSTGRES_SQL_FILE"
echo "---------------------------------"
echo "IBM Cloud Container Registry URL : $IBM_CR_SERVER"
echo "Registry Namespace               : $CR_NAMESPACE"
echo "---------------------------------"
echo "IBM Cloud RESOURCE_GROUP         : $RESOURCE_GROUP"
echo "IBM Cloud REGION                 : $REGION"
echo "---------------------------------"
echo ""
echo "Verify parameters and press return"
read input

# **********************************************************************************
# Functions definition
# **********************************************************************************

setupCLIenvCE() {
  echo "**********************************"
  echo " Using following project: $PROJECT_NAME" 
  echo "**********************************"
  
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION

  ibmcloud ce project get --name $PROJECT_NAME
  ibmcloud ce project select -n $PROJECT_NAME
  
  #to use the kubectl commands
  ibmcloud ce project select -n $PROJECT_NAME --kubecfg
  
  NAMESPACE=$(ibmcloud ce project get --name $PROJECT_NAME --output json | grep "namespace" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
  echo "Namespace: $NAMESPACE"
  kubectl get pods -n $NAMESPACE
}

cleanIBMContainerImages() {

    echo "delete images"
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    ibmcloud target
    # login with buildah
    ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $REGISTRY_URL

    ibmcloud cr image-rm $SERVICE_CATALOG_IMAGE
    ibmcloud cr image-rm $FRONTEND_IMAGE

}

cleanIBMContainerNamespace () {

    echo "delete namespace"
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    ibmcloud target
    # login with buildah
    ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | buildah login -u iambearer --password-stdin $REGISTRY_URL

    ibmcloud cr namespace-rm $CR_NAMESPACE  
}

cleanCEsecrets () {
    
    echo "delete secrects postgres"
    ibmcloud ce secret delete --name postgres.certificate-data --force
    ibmcloud ce secret delete --name postgres.username --force
    ibmcloud ce secret delete --name postgres.password --force
    ibmcloud ce secret delete --name postgres.url --force

    echo "delete secrets appid" 
    ibmcloud ce secret delete --name appid.discovery-endpoint --force
    ibmcloud ce secret delete --name appid.oauthserverurl --force
    ibmcloud ce secret delete --name appid.client-id-catalog-service --force
    ibmcloud ce secret delete --name appid.client-id-fronted  --force

}

cleanCEapplications () {

    ibmcloud ce application delete --name $FRONTEND_NAME  --force
    ibmcloud ce application delete --name $SERVICE_CATALOG_NAME  --force
}

cleanCEregistry(){

    ibmcloud ce registry delete --name $SECRET_NAME
}

cleanKEYS () {

   echo "IBM Cloud Key: $IBMCLOUDCLI_KEY_NAME"
   #List api-keys
   ibmcloud iam api-keys | grep $IBMCLOUDCLI_KEY_NAME
   #Delete api-key
   ibmcloud iam api-key-delete $IBMCLOUDCLI_KEY_NAME -f
   
   #AppID
   ibmcloud resource service-keys | grep $APPID_SERVICE_KEY_NAME
   ibmcloud resource service-keys --instance-name $APPID_SERVICE_INSTANCE_NAME
   ibmcloud resource service-key-delete $APPID_SERVICE_KEY_NAME -f

   #Postgres
   ibmcloud resource service-keys | grep $POSTGRES_SERVICE_NAME
   ibmcloud resource service-keys --instance-name $POSTGRES_SERVICE_NAME
   ibmcloud resource service-key-delete $POSTGRES_SERVICE_KEY_NAME -f
}

cleanAppIDservice (){ 
    ibmcloud resource service-instance $APPID_SERVICE_INSTANCE_NAME
    ibmcloud resource service-instance-delete $APPID_SERVICE_INSTANCE_NAME -f
}

cleanPostgresService (){ 
    ibmcloud resource service-instance $POSTGRES_SERVICE_INSTANCE
    ibmcloud resource service-instance-delete $POSTGRES_SERVICE_INSTANCE -f
}

cleanCodeEngineProject (){ 
   ibmcloud ce project delete --name $PROJECT_NAME
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " CLI config"
echo "************************************"

setupCLIenvCE

echo "************************************"
echo " Clean secrets"
echo "************************************"

cleanCEsecrets

echo "************************************"
echo " Clean CE apps"
echo "************************************"

cleanCEapplications

echo "************************************"
echo " Clean CE registry"
echo "************************************"

cleanCEregistry

echo "************************************"
echo " Clean IBM  ContainerImages registry"
echo "************************************"

cleanIBMContainerImages
# To avoid deletion of the Container Registry Namespace 
# please comment out the `cleanIBMContainerNamespace`
cleanIBMContainerNamespace

echo "************************************"
echo " Clean keys "
echo " - $IBMCLOUDCLI_KEY_NAME"
echo " - $APPID_SERVICE_KEY_NAME"
echo " - $POSTGRES_SERVICE_KEY_NAME"
echo "************************************"

cleanKEYS

echo "************************************"
echo " Clean AppID service $APPID_INSTANCE_NAME"
echo "************************************"

cleanAppIDservice

echo "************************************"
echo " Clean Postgres service $POSTGRES_SERVICE_INSTANCE"
echo "************************************"

cleanPostgresService

echo "************************************"
echo " Clean Code Engine Project $PROJECT_NAME"
echo "************************************"

# To avoid the deletion of the Code Engine project 
# please comment out the `cleanCodeEngineProject`
cleanCodeEngineProject