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
echo "Tenant configuration         : $1"
echo "---------------------------------"

# **************** Global variables set by parameters

# Code Engine
export PROJECT_NAME=$(cat ./$1 | jq '.[].codeengine.PROJECT_NAME' | sed 's/"//g') 
# postgres
export POSTGRES_SERVICE_INSTANCE=$(cat ./$1 | jq '.[].postgres.POSTGRES_SERVICE_INSTANCE' | sed 's/"//g') 
export POSTGRES_SERVICE_KEY_NAME=$(cat ./$1 | jq '.[].postgres.POSTGRES_SERVICE_KEY_NAME' | sed 's/"//g')
export POSTGRES_SQL_FILE=$(cat ./$1 | jq '.[].postgres.POSTGRES_SQL_FILE' | sed 's/"//g')
# ecommerce application container registry
export FRONTEND_IMAGE=$(cat ./$1 | jq '.[].container_images.FRONTEND_IMAGE' | sed 's/"//g')
export SERVICE_CATALOG_IMAGE=$(cat ./$1 | jq '.[].container_images.SERVICE_CATALOG_IMAGE' | sed 's/"//g')
# ecommerce application names
export SERVICE_CATALOG_NAME=$(cat ./$1 | jq '.[].applications.SERVICE_CATALOG_NAME' | sed 's/"//g')
export FRONTEND_NAME=$(cat ./$1 | jq '.[].applications.FRONTEND_NAME' | sed 's/"//g')
export FRONTEND_CATEGORY=$(cat ./$1 | jq '.[].applications.FRONTEND_CATEGORY' | sed 's/"//g')
# App ID
export APPID_SERVICE_INSTANCE_NAME=$(cat ./$1 | jq '.[].appid.APPID_SERVICE_INSTANCE_NAME' | sed 's/"//g')
export APPID_SERVICE_KEY_NAME=$(cat ./$1 | jq '.[].appid.APPID_SERVICE_KEY_NAME' | sed 's/"//g')
# IBM Cloud Container Registry
export IBM_CR_SERVER=$(cat ./$1 | jq '.[].container_ibmregistry.IBMCLOUD_CR_REGION_URL' | sed 's/"//g')
# IBM Cloud target
export RESOURCE_GROUP=$(cat ./$1 | jq '.[].ibmcloud_target.RESOURCE_GROUP' | sed 's/"//g')
export REGION=$(cat ./$1 | jq '.[].ibmcloud_target.REGION' | sed 's/"//g')

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
echo "---------------------------------"
echo "IBM Cloud RESOURCE_GROUP         : $RESOURCE_GROUP"
echo "IBM Cloud REGION                 : $REGION"
echo "---------------------------------"
echo ""
echo "Verify parameters and press return"

read input

# **************** Global variables

export NAMESPACE=""

# CE for IBM Cloud Container Registry access
export SECRET_NAME="multi.tenancy.cr.sec"
export IBMCLOUDCLI_KEY_NAME="cliapikey_for_multi_tenant_$PROJECT_NAME"

# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenvCE() {
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

function cleanIBMContainerImages() {

    echo "delete images"
    ibmcloud cr login
    ibmcloud cr image-rm $SERVICE_CATALOG_IMAGE
    ibmcloud cr image-rm $FRONTEND_IMAGE

}

function cleanCEsecrets () {
    
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

function cleanCEapplications () {

    ibmcloud ce application delete --name $FRONTEND_NAME  --force
    ibmcloud ce application delete --name $SERVICE_CATALOG_NAME  --force
}

function cleanCEregistry(){

    ibmcloud ce registry delete --name $SECRET_NAME
}

function cleanKEYS () {

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

function cleanAppIDservice (){ 
    ibmcloud resource service-instance $APPID_SERVICE_INSTANCE_NAME
    ibmcloud resource service-instance-delete $APPID_SERVICE_INSTANCE_NAME -f
}

function cleanPostgresService (){ 
    ibmcloud resource service-instance $POSTGRES_SERVICE_INSTANCE
    ibmcloud resource service-instance-delete $POSTGRES_SERVICE_INSTANCE -f
}

function cleanCodeEngineProject (){ 
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
#cleanCodeEngineProject
