#!/bin/bash

# CLI tools Documentation
# ================
# Cloud databases

# Needed IBM Cloud CLI plugins
# =============
# - cloud databases (ibmcloud plugin install cloud-databases)

# Needed tools 
# ============
# For Postgres database
# - brew install libpq
# - brew link --force libpq
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
# postgres
export POSTGRES_SERVICE_INSTANCE=$(cat ./$2 | jq '.POSTGRES.SERVICE_INSTANCE' | sed 's/"//g') 
export POSTGRES_SERVICE_KEY_NAME=$(cat ./$2 | jq '.POSTGRES.SERVICE_KEY_NAME' | sed 's/"//g')
export POSTGRES_SQL_FILE=$(cat ./$2 | jq '.POSTGRES.SQL_FILE' | sed 's/"//g')

echo "---------------------------------"
echo "Postgres instance name           : $POSTGRES_SERVICE_INSTANCE"
echo "Postgres service key name        : $POSTGRES_SERVICE_KEY_NAME"
echo "Postgres sample data sql         : $POSTGRES_SQL_FILE"
echo "---------------------------------"
echo "IBM Cloud RESOURCE_GROUP         : $RESOURCE_GROUP"
echo "IBM Cloud REGION                 : $REGION"
echo "---------------------------------"
echo ""


# **************** Global variables set as default values
export NAMESPACE=""
export STATUS="Running"

# Postgres Service
export POSTGRES_SERVICE_NAME=databases-for-postgresql
export POSTGRES_PLAN=standard
export POSTGRES_CONFIG_FOLDER="postgres-config"

# Postgres database defaults
export POSTGRES_CERTIFICATE_DATA=""
export POSTGRES_USERNAME=""
export POSTGRES_PASSWORD=""
export POSTGRES_URL=""

# **********************************************************************************
# Functions definition
# **********************************************************************************

setupCLIenv() {
  echo "**********************************"
  echo " Using following: "
  echo " - Resource group: $RESOURCE_GROUP " 
  echo " - Region: $REGION " 
  echo "**********************************"

  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
}

# **** Postgres ****

createPostgres () {
    echo ""
    echo "+++++++++++++++++++++++++"
    echo "Create postgres instance"
    echo "+++++++++++++++++++++++++"
    echo ""
    
    echo ""
    echo "-------------------------"
    echo "Create postgres service $POSTGRES_SERVICE_INSTANCE"
    echo "-------------------------"
    echo "" 
    RESULT=$(ibmcloud resource service-instance $POSTGRES_SERVICE_INSTANCE --location $REGION -g $RESOURCE_GROUP | grep "OK")
    echo "Postgres: '$RESULT'"
    if [[ $RESULT == "OK" ]]; then
        echo "*** The postgres database '$POSTGRES_SERVICE_INSTANCE' already exists!"
        echo "*** The script 'ce-install-application.sh' ends here!"
        exit 1
    fi
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

extractPostgresConfiguration () {
    echo ""
    echo "+++++++++++++++++++++++++"
    echo "Extract postgres configuration"
    echo "+++++++++++++++++++++++++"
    echo ""
    # ***** Get service key of the service
    ibmcloud resource service-key $POSTGRES_SERVICE_KEY_NAME --output JSON > ./postgres-config/postgres-key-temp.json  

    # ***** Extract needed configuration of the service key

    POSTGRES_CERTIFICATE_CONTENT_ENCODED=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.cli.certificate.certificate_base64' | sed 's/"//g' ) 
    POSTGRES_USERNAME=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.authentication.username' | sed 's/"//g' )
    POSTGRES_PASSWORD=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.authentication.password' | sed 's/"//g' )
    POSTGRES_HOST=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.hosts[].hostname' | sed 's/"//g' )
    POSTGRES_PORT=$(cat ./$POSTGRES_CONFIG_FOLDER/postgres-key-temp.json | jq '.[].credentials.connection.postgres.hosts[].port' | sed 's/"//g' )

    # ***** Build needed cert content format  
    echo "$POSTGRES_CERTIFICATE_CONTENT_ENCODED" | base64 -d -o ./$POSTGRES_CONFIG_FOLDER/cert.temp
    POSTGRES_CERTIFICATE_DATA=$(<./$POSTGRES_CONFIG_FOLDER/cert.temp)
    rm -f ./"$POSTGRES_CONFIG_FOLDER"/cert.temp

    # ***** Build postgres URL
    CONNECTION_TYPE='jdbc:postgresql://'
    CERTIFICATE_PATH='/cloud-postgres-cert'
    DATABASE_NAME="ibmclouddb"
    POSTGRES_URL="$CONNECTION_TYPE$POSTGRES_HOST:$POSTGRES_PORT/$DATABASE_NAME?sslmode=verify-full&sslrootcert=$CERTIFICATE_PATH"

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

createTablesPostgress () {
    echo ""
    echo "+++++++++++++++++++++++++"
    echo "Create table in postgres"
    echo "+++++++++++++++++++++++++"
    echo ""

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
    echo "Prepare postgres connection command: $POSTGRES_CONNECTION_TEMP"
    echo "-------------------------"
    export POSTGRES_CONNECTION="$POSTGRES_CONNECTION_TEMP' -a -f $POSTGRES_SQL_FILE"
    echo ""
    echo "-------------------------"
    echo "Postgres connection command: [$POSTGRES_CONNECTION]" 
    echo "-------------------------"
    
    # **** Get cert
    echo ""
    echo "-------------------------"
    echo "Get certificate"
    echo "-------------------------"
    echo ""  
    cd $POSTGRES_CONFIG_FOLDER
    echo "-------------------------"
    echo "Current path"
    pwd
    # **** Create a tmp folder for the 'postgres_cert'
    TMP_FOLDER=postgres_temp_cert
    mkdir $TMP_FOLDER
    cd $TMP_FOLDER
    echo "-------------------------"
    echo "Temp path"
    pwd
    ibmcloud cdb deployment-cacert $POSTGRES_SERVICE_INSTANCE \
                                    --save \
                                    --certroot .

    # **** Get connection to postgres with cert
    echo "-------------------------"
    echo "Get connection to postgres with cert"
    echo "-------------------------"
    echo ""
    ibmcloud cdb deployment-connections "$POSTGRES_SERVICE_INSTANCE" \
                                        --certroot . 
    # **** Copy needed sql script
    cp ../"$POSTGRES_SQL_FILE" ./"$POSTGRES_SQL_FILE"
    # **** Create bash script
    sed "s+COMMAND_INSERT+$POSTGRES_CONNECTION+g" "../insert-template.sh" > ./insert.sh
    # **** Execute the bash script with the extracted format
    echo "-------------------------"
    echo "Create table in postgres using ($POSTGRES_SQL_FILE)"
    echo "-------------------------"
    echo ""
    cat insert.sh
    echo "------------------------------"
    echo "Verify the given entries and press return"
    echo "------------------------------"
    bash insert.sh
    cd ..
    echo "-------------------------"
    echo "Clean up"
    pwd
    # **** Clean-up the temp folder and content
    rm -f -r ./$TMP_FOLDER
    cd ..
    echo "-------------------------"
    echo "Done"
    pwd
}

# **** application and microservices ****

checkKubernetesPod (){
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

setupCLIenv

echo "************************************"
echo " Create Postgres instance and database"
echo "************************************"

createPostgres
createTablesPostgress
extractPostgresConfiguration

echo "************************************"
echo " Relevant Postgres configuration"
echo "************************************"
echo "-------------------------"
echo "POSTGRES_CERTIFICATE_DATA:  $POSTGRES_CERTIFICATE_DATA"
echo "POSTGRES_USERNAME:          $POSTGRES_USERNAME"
echo "POSTGRES_PASSWORD:          $POSTGRES_PASSWORD"
echo "POSTGRES_URL     :          $POSTGRES_URL"
echo "------------------------------"
echo "Verify the given entries and press return"
echo "------------------------------"
