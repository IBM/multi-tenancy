#!/bin/bash

# Needed tools 
# ============
# Install jq to extract json in bash on mac
# - brew install jq

# **********************************************************************************
# Set global variables using parameters
# **********************************************************************************

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
# IBM Cloud target
export RESOURCE_GROUP=$(cat ./$1 | jq '.IBM_CLOUD.RESOURCE_GROUP' | sed 's/"//g')
export REGION=$(cat ./$1 | jq '.IBM_CLOUD.REGION' | sed 's/"//g')

# Tenant config
# --------------
# App ID
export APPID_SERVICE_INSTANCE_NAME=$(cat ./$2 | jq '.APP_ID.SERVICE_INSTANCE' | sed 's/"//g')
export APPID_SERVICE_KEY_NAME=$(cat ./$2 | jq '.APP_ID.SERVICE_KEY_NAME' | sed 's/"//g')
# ecommerce application names
export FRONTEND_NAME=$(cat ./$2 | jq '.APPLICATION.CONTAINER_NAME_FRONTEND' | sed 's/"//g')

echo "Application Frontend name        : $FRONTEND_NAME"
echo "---------------------------------"
echo "App ID service instance name     : $APPID_SERVICE_INSTANCE_NAME"
echo "App ID service key name          : $APPID_SERVICE_KEY_NAME"
echo "---------------------------------"
echo "IBM Cloud RESOURCE_GROUP         : $RESOURCE_GROUP"
echo "IBM Cloud REGION                 : $REGION"
echo "---------------------------------"
echo ""
echo "------------------------------"
echo "Verify parameters and press return"
read input

# **************** Global variables set as default values

# AppID Service
export SERVICE_PLAN="graduated-tier"
export APPID_SERVICE_NAME="appid"
export APPID_SERVICE_KEY_ROLE="Manager"
export TENANTID=""
export MANAGEMENTURL=""
export APPLICATION_DISCOVERYENDPOINT=""

# AppID User
export USER_IMPORT_FILE="appid-configs/user-import.json"
export USER_EXPORT_FILE="appid-configs/user-export.json"
export ENCRYPTION_SECRET="12345678"

# AppID Application configuration
export ADD_APPLICATION="appid-configs/add-application.json"
export ADD_SCOPE="appid-configs/add-scope.json"
export ADD_ROLE="appid-configs/add-roles.json"
export ADD_REDIRECT_URIS="appid-configs/add-redirecturis.json"
export ADD_UI_TEXT="appid-configs/add-ui-text.json"
export ADD_IMAGE="appid-images/logo.png"
export ADD_COLOR="appid-configs/add-ui-color.json"
export APPLICATION_CLIENTID=""
export APPLICATION_TENANTID=""
export APPLICATION_OAUTHSERVERURL=""

# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenv() {
  echo "**********************************"
  echo " Using following: "
  echo " - Resource group: $RESOURCE_GROUP " 
  echo " - Region: $REGION " 
  echo "**********************************"

  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
}

# **** AppID ****

function createAppIDService() {
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION

    # Create AppID service
    RESULT=$(ibmcloud resource service-instance $APPID_SERVICE_INSTANCE_NAME --location $REGION -g $RESOURCE_GROUP | grep "OK")
    if [[ $RESULT == "OK" ]]; then
        echo "*** The AppID service '$APPID_SERVICE_INSTANCE_NAME' already exists!"
        echo "*** The script 'ops-install-single-appid.sh' ends here!"
        exit 1
    fi
    ibmcloud resource service-instance-create $APPID_SERVICE_INSTANCE_NAME $APPID_SERVICE_NAME $SERVICE_PLAN $REGION
    # Create a service key for the service
    ibmcloud resource service-key-create $APPID_SERVICE_KEY_NAME $APPID_SERVICE_KEY_ROLE --instance-name $APPID_SERVICE_INSTANCE_NAME
    # Get the tenantId of the AppID service key
    TENANTID=$(ibmcloud resource service-keys --instance-name $APPID_SERVICE_INSTANCE_NAME --output json | grep "tenantId" | awk '{print $2;}' | sed 's/"//g')
    echo "Tenant ID: $TENANTID"
    # Get the managementUrl of the AppID from service key
    MANAGEMENTURL=$(ibmcloud resource service-keys --instance-name $APPID_SERVICE_INSTANCE_NAME --output json | grep "managementUrl" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
    echo "Management URL: $MANAGEMENTURL"
}

function configureAppIDInformation(){

    #****** Set identity providers
    echo ""
    echo "-------------------------"
    echo " Set identity providers"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-custom.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/custom)
    echo ""
    echo "-------------------------"
    echo "Result custom: $result"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-facebook.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/facebook)
    echo ""
    echo "-------------------------"
    echo "Result facebook: $result"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-google.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/google)
    echo ""
    echo "-------------------------"
    echo "Result google: $result"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./appid-configs/idps-clouddirectory.json -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/idps/cloud_directory)
    echo ""
    echo "-------------------------"
    echo "Result cloud directory: $result"
    echo "-------------------------"
    echo ""

    #****** Add application ******
    echo ""
    echo "-------------------------"
    echo " Create application"
    echo "-------------------------"
    echo ""
    sed "s+FRONTENDNAME+$FRONTEND_NAME+g" ./appid-configs/add-application-template.json > ./$ADD_APPLICATION
    result=$(curl -d @./$ADD_APPLICATION -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/applications)
    echo "-------------------------"
    echo "Result application: $result"
    echo "-------------------------"
    APPLICATION_CLIENTID=$(echo $result | sed -n 's|.*"clientId":"\([^"]*\)".*|\1|p')
    APPLICATION_TENANTID=$(echo $result | sed -n 's|.*"tenantId":"\([^"]*\)".*|\1|p')
    APPLICATION_OAUTHSERVERURL=$(echo $result | sed -n 's|.*"oAuthServerUrl":"\([^"]*\)".*|\1|p')
    APPLICATION_DISCOVERYENDPOINT=$(echo $result | sed -n 's|.*"discoveryEndpoint":"\([^"]*\)".*|\1|p')
    echo "ClientID: $APPLICATION_CLIENTID"
    echo "TenantID: $APPLICATION_TENANTID"
    echo "oAuthServerUrl: $APPLICATION_OAUTHSERVERURL"
    echo "discoveryEndpoint: $APPLICATION_DISCOVERYENDPOINT"
    echo ""

    #****** Add scope ******
    echo ""
    echo "-------------------------"
    echo " Add scope"
    echo "-------------------------"
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./$ADD_SCOPE -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/applications/$APPLICATION_CLIENTID/scopes)
    echo "-------------------------"
    echo "Result scope: $result"
    echo "-------------------------"
    echo ""

    #****** Add role ******
    echo "-------------------------"
    echo " Add role"
    echo "-------------------------"
    #Create file from template
    sed "s+APPLICATIONID+$APPLICATION_CLIENTID+g" ./appid-configs/add-roles-template.json > ./$ADD_ROLE
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    #echo $OAUTHTOKEN
    result=$(curl -d @./$ADD_ROLE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/roles)
    rm -f ./$ADD_ROLE
    echo "-------------------------"
    echo "Result role: $result"
    echo "-------------------------"
    echo ""
 
    #****** Import cloud directory users ******
    echo ""
    echo "-------------------------"
    echo " Cloud directory import users"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    result=$(curl -d @./$USER_IMPORT_FILE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/cloud_directory/import?encryption_secret=$ENCRYPTION_SECRET)
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""

    #******* Configure ui text  ******
    echo ""
    echo "-------------------------"
    echo " Configure ui text"
    echo "-------------------------"
    echo ""
    sed "s+FRONTENDNAME+$FRONTEND_NAME+g" ./appid-configs/add-ui-text-template.json > ./$ADD_UI_TEXT
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "PUT url: $MANAGEMENTURL/config/ui/theme_txt"
    result=$(curl -d @./$ADD_UI_TEXT -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_text)
    rm -f $ADD_UI_TEXT
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""

    #******* Configure ui color  ******
    echo ""
    echo "-------------------------"
    echo " Configure ui color"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "PUT url: $MANAGEMENTURL/config/ui/theme_color"
    result=$(curl -d @./$ADD_COLOR -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_color)
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""

    #******* Configure ui image  ******
    echo ""
    echo "-------------------------"
    echo " Configure ui image"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "POST url: $MANAGEMENTURL/config/ui/media?mediaType=logo"
    result=$(curl -F "file=@./$ADD_IMAGE" -H "Content-Type: multipart/form-data" -X POST -v -H "Authorization: Bearer $OAUTHTOKEN" "$MANAGEMENTURL/config/ui/media?mediaType=logo")
    echo "-------------------------"
    echo "Result import: $result"
    echo "-------------------------"
    echo ""
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " CLI config"
echo "************************************"

setupCLIenv

echo "************************************"
echo " AppID creation"
echo "************************************"

createAppIDService

echo "************************************"
echo " AppID configuration"
echo "************************************"

configureAppIDInformation

echo "************************************"
echo " AppID URLs and IDs"
echo "************************************"
echo "- ClientID: $APPLICATION_CLIENTID"
echo "- TenantID: $APPLICATION_TENANTID"
echo "- oAuthServerUrl: $APPLICATION_OAUTHSERVERURL"
echo "- discoveryEndpoint: $APPLICATION_DISCOVERYENDPOINT"
echo "------------------------------"
echo "Verify the given entries and press return"
echo "------------------------------"
