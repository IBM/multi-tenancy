#!/bin/bash

echo ""
echo "Parameter count : $@"
echo "Parameter zero 'name of the script': $0"
echo "---------------------------------"
echo "Code Engine project name         : $1"
echo "---------------------------------"
echo "App ID service instance name     : $2"
echo "App ID service key name          : $3"
echo "---------------------------------"
echo "Application Service Catalog name : $4"
echo "Application Frontend name        : $5"
echo "---------------------------------"
echo "Postgres instance name           : $6"
echo "Postgres service key name        : $7"
echo "---------------------------------"
echo ""

# **************** Global variables set by parameters
# Code Engine
export PROJECT_NAME=$1

# App ID
export APPID_INSTANCE_NAME=$2
export APPID_SERVICE_KEY_NAME=$3

# CE applications
export SERVICE_CATALOG=$4
export FRONTEND=$5

# Postgres
export POSTGRES_SERVICE_INSTANCE=$6
export POSTGRES_SERVICE_KEY_NAME=$7

# **************** Global variables

export RESOURCE_GROUP=default
export REGION="us-south"
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

function cleanCEapplications () {
    ibmcloud ce application delete --name $FRONTEND  --force
    ibmcloud ce application delete --name $SERVICE_CATALOG  --force
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
   ibmcloud resource service-keys --instance-name $APPID_INSTANCE_NAME
   ibmcloud resource service-key-delete $APPID_SERVICE_KEY_NAME -f

   #Postgres
   ibmcloud resource service-keys | grep $POSTGRES_SERVICE_NAME
   ibmcloud resource service-keys --instance-name $POSTGRES_SERVICE_NAME
   ibmcloud resource service-key-delete $POSTGRES_SERVICE_KEY_NAME -f
}

function cleanAppIDservice (){ 
    ibmcloud resource service-instance $APPID_INSTANCE_NAME
    ibmcloud resource service-instance-delete $APPID_INSTANCE_NAME -f
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
echo " Clean CE apps"
echo "************************************"

cleanCEapplications

echo "************************************"
echo " Clean CE registry"
echo "************************************"

cleanCEregistry

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
