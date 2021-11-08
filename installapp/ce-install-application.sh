#!/bin/bash

# CLI tools Documentation
# ================
# Code Engine: https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli#cli-application-create
# libpq: https://www.compose.com/articles/postgresql-tips-installing-the-postgresql-client/?_ga=2.31285695.124869551.1633324536-496882334.1633002728
# Cloud databases

# Needed IBM CLoud CLI plugins
# =============
# - code engine 
# - cloud databases (ibmcloud plugin install cloud-databases)

# Needed tools 
# ============
# brew install libpq
# brew link --force libpq   

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
echo "Code Engine project name         : $1"
echo "---------------------------------"
echo "App ID service instance name     : $2"
echo "App ID service key name          : $3"
echo "---------------------------------"
echo "Application Service Catalog name : $4"
echo "Application Frontend name        : $5"
echo "Application Service Catalog image: $6"
echo "Application Frontend image       : $7"
echo "Application Frontend category    : $8"
echo "---------------------------------"
echo "Postgres instance name           : $9"
echo "Postgres service key name        : $10"
echo "Postgres sample data sql         : $11"
echo "---------------------------------"
echo ""

# **************** Global variables set by parameters

# Code Engine
export PROJECT_NAME=$1
# App
export YOUR_SERVICE_FOR_APPID=$2
export APPID_SERVICE_KEY_NAME=$3
# ecommerce application names
export SERVICE_CATALOG_NAME=$4
export FRONTEND_NAME=$5
export FRONTEND_CATEGORY=$8
# Postgres database configuration
export POSTGRES_SERVICE_INSTANCE=$9
export POSTGRES_SERVICE_KEY_NAME=$10
export POSTGRES_SQL_FILE=$11"create-populate-tenant-a.sql"

# **************** Global variables set as default values

export RESOURCE_GROUP=default
export REGION="us-south"
export NAMESPACE=""
export STATUS="Running"
export SECRET_NAME="multi.tenancy.cr.sec"
export EMAIL=thomas@example.com

# ecommerce application container registry
export FRONTEND_IMAGE=$7
export SERVICE_CATALOG_IMAGE=$6

# ecommerce application URLs
export FRONTEND_URL=""
export SERVICE_CATALOG_URL=""

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

# Postgres Service
export POSTGRES_SERVICE_NAME=databases-for-postgresql
export POSTGRES_PLAN=standard
export POSTGRES_CONFIG_FOLDER="postgres-config"

# Postgres database defaults
export POSTGRES_CERTIFICATE_DATA=""
export POSTGRES_USERNAME=""
export POSTGRES_PASSWORD=""
export POSTGRES_URL=""
export POSTGRES_USE_CERT="&sslrootcert=/cloud-postgres-cert"


# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenvCE() {
  echo "**********************************"
  echo " Using following project: $PROJECT_NAME" 
  echo "**********************************"

  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION

  ibmcloud ce project create --name $PROJECT_NAME 

  ibmcloud ce project get --name $PROJECT_NAME
  ibmcloud ce project select -n $PROJECT_NAME
  
  #to use the kubectl commands
  ibmcloud ce project select -n $PROJECT_NAME --kubecfg
  
  NAMESPACE=$(ibmcloud ce project get --name $PROJECT_NAME --output json | grep "namespace" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
  echo "Namespace: $NAMESPACE"
  kubectl get pods -n $NAMESPACE

  CHECK=$(ibmcloud ce project get -n $PROJECT_NAME | awk '/Apps/ {print $2;}')
  echo "**********************************"
  echo "Check for existing apps? '$CHECK'"
  echo "**********************************"
  if [ $CHECK != 0 ];
  then
    echo "Error: There are remaining '$CHECK' apps."
    echo "Wait until all apps are deleted inside the $PROJECT_NAME."
    echo "The script exits here!"
    exit 1
  fi
}

function setupCRenvCE() {
   
   IBMCLOUDCLI_KEY_NAME="cliapikey_for_multi_tenant_$PROJECT_NAME"
   IBMCLOUDCLI_KEY_DESCRIPTION="CLI APIkey $IBMCLOUDCLI_KEY_NAME"
   CLIKEY_FILE="cli_key.json"
   CR_SERVER="us.icr.io"
   USERNAME="iamapikey"

   ibmcloud iam api-key-create $IBMCLOUDCLI_KEY_NAME -d "My IBM CLoud CLI API key for project $PROJECT_NAME" --file $CLIKEY_FILE
   CLIAPIKEY=$(cat $CLIKEY_FILE | grep '"apikey":' | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g' )
   #echo $CLIKEY
   rm -f $CLIKEY_FILE

   ibmcloud ce registry create --name $SECRET_NAME \
                               --server $CR_SERVER \
                               --username $USERNAME \
                               --password $CLIAPIKEY \
                               --email $EMAIL
}

# **** Postgres ****

function setupPostgres () {
    
    echo ""
    echo "-------------------------"
    echo "Create postgres service $POSTGRES_SERVICE_INSTANCE"
    echo "-------------------------"
    echo "" 
    ibmcloud resource service-instance-create $POSTGRES_SERVICE_INSTANCE $POSTGRES_SERVICE_NAME $POSTGRES_PLAN $REGION \
                                             -g $RESOURCE_GROUP
    # ***** Wait for postgres instance
    echo ""
    echo "-------------------------"
    echo "Wait for postgres instance, it can take up to 10 minutes"
    echo "-------------------------"
    echo ""
    export STATUS_POSTGRES="succeeded"
    export TMP_STATUS="FAILED"
    while :
        do
            FIND="Postgres database"
            STATUS_CHECK=$(ibmcloud resource service-instance $POSTGRES_SERVICE_INSTANCE --output json | grep '"state":' | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
            echo "Status: $STATUS_CHECK"
            STATUS_VERIFICATION=$(echo "$STATUS_CHECK" | grep "FAILED")
            if [ "$STATUS_VERIFICATION" = "$TMP_STATUS" ]; then
                echo "$(date +'%F %H:%M:%S') Status: $FIND not found, I will stop the script"
                echo "------------------------------------------------------------------------"
                break
            fi
            STATUS_VERIFICATION=$(echo "$STATUS_CHECK" | grep "succeeded")
            if [ "$STATUS_VERIFICATION" = "$STATUS_POSTGRES" ]; then
                echo "$(date +'%F %H:%M:%S') Status: $FIND is Ready"
                echo "------------------------------------------------------------------------"
                break
            else
                echo "$(date +'%F %H:%M:%S') Status: $FIND($STATUS_CHECK)"
                echo "------------------------------------------------------------------------"
            fi
            sleep 10
        done
    
    # ***** Get instance ID
    echo ""
    echo "-------------------------"
    echo "Get instance ID"
    echo "-------------------------"
    echo ""
    POSTGRES_INSTANCE_ID=$(ibmcloud resource service-instance $POSTGRES_SERVICE_INSTANCE --id | tail -1 | awk '{print $1;}')
    echo "Postgres instance ID: $POSTGRES_INSTANCE_ID"

    # **** Create service key and get the postgres connection
    echo ""
    echo "-------------------------"
    echo "Create service key and get the postgres connection"
    echo "-------------------------"
    echo ""
    # **** Create a service key for the service
    ibmcloud resource service-key-create $POSTGRES_SERVICE_KEY_NAME --instance-id $POSTGRES_INSTANCE_ID
}

function createTablesPostgress () {

    echo ""
    echo "-------------------------"
    echo "Get the postgres connection statement"
    echo "-------------------------"
    echo ""   
    # ***** Get service key of the service
    ibmcloud resource service-key $POSTGRES_SERVICE_KEY_NAME --output JSON > ./postgres-config/postgres-key-temp.json
    POSTGRES_CONNECTION_TEMP=$(cat ./postgres-config/postgres-key-temp.json | jq '.[].credentials.connection.cli.composed[]' | sed 's/"//g' | sed '$ s/.$//' )
    rm -f ./"$POSTGRES_CONFIG_FOLDER"/postgres-key-temp.json
    echo ""
    echo "-------------------------"
    echo "Build command step 1 : $POSTGRES_CONNECTION_TEMP"
    echo "-------------------------"
    export POSTGRES_CONNECTION="$POSTGRES_CONNECTION_TEMP' -a -f $POSTGRES_SQL_FILE"
    echo ""
    echo "-------------------------"
    echo "Result: [$POSTGRES_CONNECTION]" 
    echo "-------------------------"
    
    # **** Get cert
    echo ""
    echo "-------------------------"
    echo "Get cert"
    echo "-------------------------"
    echo ""  
    cd $POSTGRES_CONFIG_FOLDER
    echo "-------------------------"
    echo "Path"
    pwd
    # **** Create a tmp folder for the 'postgres_cert'
    TMP_FOLDER=postgres_temp_cert
    mkdir $TMP_FOLDER
    cd $TMP_FOLDER
    echo "-------------------------"
    echo "Path"
    pwd
    ibmcloud cdb deployment-cacert $POSTGRES_SERVICE_INSTANCE \
                                    --save \
                                    --certroot .

    # **** Get connection to db with cert
    echo "-------------------------"
    echo "Get connection to db with cert"
    echo "-------------------------"
    echo ""
    ibmcloud cdb deployment-connections "$POSTGRES_SERVICE_INSTANCE" \
                                        --certroot . 
    # **** Copy need sql script
    cp ../"$POSTGRES_SQL_FILE" ./"$POSTGRES_SQL_FILE"
    # **** Create bash script
    sed "s+COMMAND_INSERT+$POSTGRES_CONNECTION+g" "../insert-template.sh" > ./insert.sh
    # **** Execute the bash script with the extracted format
    bash insert.sh
    cd ..
    echo "-------------------------"
    echo "Path"
    pwd
    # **** Clean-up the temp folder and content
    rm -f -r ./$TMP_FOLDER
    cd ..
    echo "-------------------------"
    echo "Path"
    pwd
}

function extractPostgresConfiguration () {
    
    pwd

    # ***** Get service key of the service
    ibmcloud resource service-key $POSTGRES_SERVICE_KEY_NAME --output JSON > ./postgres-config/postgres-key-temp.json

    # ***** Extract needed configuration of the service key
    POSTGRES_CERTIFICATE_DATA=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.cli.certificate.certificate_base64' | sed 's/"//g' | sed '$ s/.$//' )
    POSTGRES_USERNAME=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.authentication.username' | sed 's/"//g' | sed '$ s/.$//' )
    POSTGRES_PASSWORD=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.authentication.password' | sed 's/"//g' | sed '$ s/.$//' )
    POSTGRES_URL=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.composed[]' | sed 's/"//g' )
    
    # ***** Delete temp file    
    rm -f ./"$POSTGRES_CONFIG_FOLDER"/postgres-key-temp.json
    
    # ***** verfy variables
    echo "-------------------------"
    echo "POSTGRES_CERTIFICATE_DATA:  $POSTGRES_CERTIFICATE_DATA"
    echo "POSTGRES_USERNAME:          $POSTGRES_USERNAME"
    echo "POSTGRES_PASSWORD:          $POSTGRES_PASSWORD"
    echo "POSTGRES_URL     :          $POSTGRES_URL"
    echo "-------------------------"

}

# **** AppID ****

function createAppIDService() {
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
    # Create AppID service
    ibmcloud resource service-instance-create $YOUR_SERVICE_FOR_APPID $APPID_SERVICE_NAME $SERVICE_PLAN $REGION
    # Create a service key for the service
    ibmcloud resource service-key-create $APPID_SERVICE_KEY_NAME $APPID_SERVICE_KEY_ROLE --instance-name $YOUR_SERVICE_FOR_APPID
    # Get the tenantId of the AppID service key
    TENANTID=$(ibmcloud resource service-keys --instance-name $YOUR_SERVICE_FOR_APPID --output json | grep "tenantId" | awk '{print $2;}' | sed 's/"//g')
    echo "Tenant ID: $TENANTID"
    # Get the managementUrl of the AppID from service key
    MANAGEMENTURL=$(ibmcloud resource service-keys --instance-name $YOUR_SERVICE_FOR_APPID --output json | grep "managementUrl" | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g')
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

function addRedirectURIAppIDInformation(){

    #****** Add redirect uris ******
    echo ""
    echo "-------------------------"
    echo " Add redirect uris"
    echo "-------------------------"
    echo ""
    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
    echo "Redirect URL: $FRONTEND_URL"
    #Create file from template
    sed "s+APPLICATION_REDIRECT_URL+$FRONTEND_URL+g" ./appid-configs/add-redirecturis-template.json > ./$ADD_REDIRECT_URIS
    result=$(curl -d @./$ADD_REDIRECT_URIS -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/redirect_uris)
    rm -f ./$ADD_REDIRECT_URIS
    echo "-------------------------"
    echo "Result redirect uris: $result"
    echo "-------------------------"
    echo ""
}

# **** application and microservices ****

function deployServiceCatalog(){
    OUTPUTFILE=./ce-get-application-outpout.json
    URL="$POSTGRES_URL$POSTGRES_USE_CERT"
    ibmcloud ce application create --name "$SERVICE_CATALOG_NAME" \
                                   --image "$SERVICE_CATALOG_IMAGE" \
                                   --env POSTGRES_CERTIFICATE_DATA="$POSTGRES_CERTIFICATE_DATA" \
                                   --env POSTGRES_USERNAME="$POSTGRES_USERNAME" \
                                   --env POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
                                   --env POSTGRES_URL="$URL" \
                                   --cpu "1" \
                                   --memory "4G" \
                                   --port 8081 \
                                   --registry-secret "$SECRET_NAME" \
                                   --max-scale 1 \
                                   --min-scale 1 
                                       
    SERVICE_CATALOG_URL=$(ibmcloud ce application get --name "$SERVICE_CATALOG_NAME" -o url)
    echo "Set SERVICE CATALOG URL: $SERVICE_CATALOG_URL"
}

function deployFrontend(){

    ibmcloud ce application create --name "$FRONTEND_NAME" \
                                   --image "$FRONTEND_IMAGE" \
                                   --cpu "1" \
                                   --memory "8G" \
                                   --env VUE_APPID_CLIENT_ID="$APPLICATION_CLIENTID" \
                                   --env VUE_APPID_DISCOVERYENDPOINT="$APPLICATION_DISCOVERYENDPOINT" \
                                   --env VUE_APP_API_URL_PRODUCTS="$SERVICE_CATALOG_URL/base/category" \
                                   --env VUE_APP_API_URL_ORDERS="$SERVICE_CATALOG_URL/base/customer/Orders" \
                                   --env VUE_APP_API_URL_CATEGORIES="$SERVICE_CATALOG_URL/base/category" \
                                   --env VUE_APP_CATEGORY_NAME="$FRONTEND_CATEGORY" \
                                   --env VUE_APP_HEADLINE="$FRONTEND_NAME" \
                                   --env VUE_APP_ROOT="/" \
                                   --registry-secret "$SECRET_NAME" \
                                   --max-scale 1 \
                                   --min-scale 1 \
                                   --port 8080 

    ibmcloud ce application get --name $FRONTEND_NAME
    FRONTEND_URL=$(ibmcloud ce application get --name "$FRONTEND_NAME" -o url)
    echo "Set FRONTEND URL: $FRONTEND_URL"
}

# **** Kubernetes CLI ****

function kubeDeploymentVerification(){

    echo "************************************"
    echo " pods, deployments and configmaps details "
    echo "************************************"
    
    kubectl get pods -n $NAMESPACE
    kubectl get deployments -n $NAMESPACE
    kubectl get configmaps -n $NAMESPACE

}

function getKubeContainerLogs(){

    echo "************************************"
    echo " $FRONTEND_NAME log"
    echo "************************************"

    FIND="$FRONTEND_NAME"
    FRONTEND_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $FRONTEND_LOG
    kubectl logs $FRONTEND_LOG user-container

    echo "************************************"
    echo " $SERVICE_CATALOG_NAME logs"
    echo "************************************"

    FIND=$SERVICE_CATALOG_NAME
    SERVICE_CATALOG_LOG=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $1}')
    echo $SERVICE_CATALOG_LOG
    kubectl logs $SERVICE_CATALOG_LOG user-container

}

function checkKubernetesPod (){
    application_pod="${1}" 

    array=("$application_pod")
    for i in "${array[@]}"
    do 
        echo ""
        echo "------------------------------------------------------------------------"
        echo "Check $i"
        while :
        do
            FIND=$i
            STATUS_CHECK=$(kubectl get pod -n $NAMESPACE | grep $FIND | awk '{print $3}')
            echo "Status: $STATUS_CHECK"
            if [ "$STATUS" = "$STATUS_CHECK" ]; then
                echo "$(date +'%F %H:%M:%S') Status: $FIND is Ready"
                echo "------------------------------------------------------------------------"
                break
            else
                echo "$(date +'%F %H:%M:%S') Status: $FIND($STATUS_CHECK)"
                echo "------------------------------------------------------------------------"
            fi
            sleep 5
        done
    done
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "************************************"
echo " CLI config"
echo "************************************"

setupCLIenvCE

echo "************************************"
echo " Configure container registry access"
echo "************************************"

setupCRenvCE

echo "************************************"
echo " Create Postgres instance and database"
echo "************************************"

setupPostgres
createTablesPostgress
extractPostgresConfiguration

echo "************************************"
echo " AppID creation"
echo "************************************"

createAppIDService

echo "************************************"
echo " AppID configuration"
echo "************************************"

configureAppIDInformation

echo "************************************"
echo " service catalog"
echo "************************************"

deployServiceCatalog
ibmcloud ce application events --application $SERVICE_CATALOG_NAME

echo "************************************"
echo " frontend"
echo "************************************"

deployFrontend
ibmcloud ce application events --application $FRONTEND_NAME

echo "************************************"
echo " AppID add redirect URI"
echo "************************************"

addRedirectURIAppIDInformation

echo "************************************"
echo " Verify deployments"
echo "************************************"

kubeDeploymentVerification

echo "************************************"
echo " Container logs"
echo "************************************"

getKubeContainerLogs

echo "************************************"
echo " URLs"
echo "************************************"
echo " - oAuthServerUrl   : $APPLICATION_OAUTHSERVERURL"
echo " - discoveryEndpoint: $APPLICATION_DISCOVERYENDPOINT"
echo " - Frontend         : $FRONTEND_URL"
echo " - ServiceCatalog   : $SERVICE_CATALOG_URL"
