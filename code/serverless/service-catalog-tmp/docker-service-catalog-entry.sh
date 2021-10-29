#!/bin/bash

export info=$(pwd)

echo "**********************************"
echo "Step 1"
echo "**********************************"
echo "  -> Log: Root path: '$info'"
echo "  -> Log: Check env variables:" 
echo "    - $default_datasource_certs"
echo "    - $default_datasource_certs_data"
echo "    - $POSTGRES_cert_content"
echo "**********************************"
echo ""
echo "**********************************"
echo "Step 2"
echo "**********************************"
echo " Set certifications related variables"
echo "**********************************"
export CERT_FILE_NAME=./real_cert
export CERT_CONTENT=$default_datasource_certs

echo "CERT_FILE_NAME: $CERT_FILE_NAME"
echo "CERT_CONTENT: $CERT_CONTENT"

echo ""
echo "**********************************"
echo "Step 3"
echo "**********************************"
echo " Verify that the copied file exists"
echo "**********************************"
ls

"/bin/sh" ./create-service-catalog-cert.sh

echo ""
echo "**********************************"
echo "Step 4"
echo "**********************************"
echo " Verify that the create file exists"
echo "**********************************"
ls

more ./real_cert

echo ""
echo "**********************************"
echo "Step 5"
echo "**********************************"
echo "Execute java command "
echo "**********************************"
echo ""

java -Xmx128m \
     -Xscmaxaot100m \
     -XX:+IdleTuningGcOnIdle \
     -Xtune:virtualized \
     -Xscmx128m \
     -Xshareclasses:cacheDir=/opt/shareclasses \
     -jar \
     /deployments/quarkus-run.jar

#java -Xmx128m \
#     -Xscmaxaot100m \
#     -XX:+IdleTuningGcOnIdle \
#     -Xtune:virtualized \
#     -Xscmx128m \
#     -Xshareclasses:cacheDir=/opt/shareclasses \
#     -D_POSTGRES_1=${POSTGRES_1} \
#     -D_POSTGRES_2=${POSTGRES_2} \
#     -D_CERT_FILE_NAME=${CERT_FILE_NAME} \
#     - cp D_CERT_FILE_NAME \
#     -jar \
#     /deployments/quarkus-run.jar
