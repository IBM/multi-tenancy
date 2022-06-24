#!/bin/bash

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
echo "Code Engine Region           : $1"
echo "Container Registry Namespace : $2"
echo "Resource Group Name          : $3"
echo "---------------------------------"

export REGION=${REGION:-${1}}
export NAMESPACE=${NAMESPACE:-${2}}
export RESOURCE_GROUP=${RESOURCE_GROUP:-${3}}
export RANDOM8=$(echo ${NAMESPACE} | cut -f3 -d"-")

# Configurations
export GLOBAL="../configuration/global.json"
export TENANT_A="../configuration/tenants/tenant-a.json"
export TENANT_B="../configuration/tenants/tenant-b.json"

# **********************************************************************************
# Determine host for Container Registry based on region
# **********************************************************************************

case $REGION in
  us-south)
    export REGISTRY_URL=us.icr.io 
    ;;
  ca-tor)
    export REGISTRY_URL=ca.icr.io
    ;;
  eu-gb)
    export REGISTRY_URL=uk.icr.io
    ;;
  eu-de)
    export REGISTRY_URL=de.icr.io
    ;;
  jp-tok)
    export REGISTRY_URL=jp.icr.io
    ;;
  au-syd)
    export REGISTRY_URL=au.icr.io
    ;;
esac 

# **********************************************************************************
# Update global configuration properties
# **********************************************************************************

sed -i.bak "s/default/${RESOURCE_GROUP}/" ${GLOBAL} && rm ${GLOBAL}.bak
sed -i.bak "s/eu-de/${REGION}/" ${GLOBAL} && rm ${GLOBAL}.bak
sed -i.bak "s/de\.icr\.io/${REGISTRY_URL}/" ${GLOBAL} && rm ${GLOBAL}.bak
sed -i.bak "s/multi-tenancy-example/${NAMESPACE}/" ${GLOBAL} && rm ${GLOBAL}.bak

# **********************************************************************************
# Update Tenant A configuration properties
# **********************************************************************************

sed -i.bak "s/multi-tenancy-serverless-appid-a/${NAMESPACE}-00/" ${TENANT_A}&& rm ${TENANT_A}.bak
sed -i.bak "s/itzce/appid/" ${TENANT_A}&& rm ${TENANT_A}.bak
sed -i.bak "s/multi-tenancy-serverless-appid-key-a/appid-service-key-${RANDOM8}-00/" ${TENANT_A}&& rm ${TENANT_A}.bak
sed -i.bak "s/multi-tenancy-serverless-pg-ten-a-key/pgsql-service-key-${RANDOM8}-00/" ${TENANT_A}&& rm ${TENANT_A}.bak
sed -i.bak "s/multi-tenancy-serverless-pg-ten-a/${NAMESPACE}-00/" ${TENANT_A}&& rm ${TENANT_A}.bak
sed -i.bak "s/itzce/pgsql/" ${TENANT_A}&& rm ${TENANT_A}.bak
sed -i.bak "s/multi-tenancy-serverless-a/${NAMESPACE}-00/" ${TENANT_A}&& rm ${TENANT_A}.bak

# **********************************************************************************
# Update Tenant B configuration properties
# **********************************************************************************

sed -i.bak "s/multi-tenancy-serverless-appid-b/${NAMESPACE}-01/" ${TENANT_B}&& rm ${TENANT_B}.bak
sed -i.bak "s/itzce/appid/" ${TENANT_B}&& rm ${TENANT_B}.bak
sed -i.bak "s/multi-tenancy-serverless-appid-key-b/appid-service-key-${RANDOM8}-01/" ${TENANT_B}&& rm ${TENANT_B}.bak
sed -i.bak "s/multi-tenancy-serverless-pg-ten-b-key/pgsql-service-key-${RANDOM8}-01/" ${TENANT_B}&& rm ${TENANT_B}.bak
sed -i.bak "s/multi-tenancy-serverless-pg-ten-b/${NAMESPACE}-01/" ${TENANT_B}&& rm ${TENANT_B}.bak
sed -i.bak "s/itzce/pgsql/" ${TENANT_B}&& rm ${TENANT_B}.bak
sed -i.bak "s/multi-tenancy-serverless-b/${NAMESPACE}-01/" ${TENANT_B}&& rm ${TENANT_B}.bak