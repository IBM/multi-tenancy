#!/bin/bash
#export REPOSITORY=$MY_REPOSITORY # Example to set the variable: export MY_REPOSITORY=tsuedbroecker
export REPOSITORY=kdeif # Example to set the variable: export MY_REPOSITORY=tsuedbroecker

echo "************************************"
echo " frontend"
echo "************************************"
#docker login quay.io

echo "************************************"
echo " Build frontend"
echo "************************************"
#docker build -t "quay.io/$REPOSITORY/frontend:v0.0" -f Dockerfile.os4-webapp .
docker build -t "frontend:v0.0" -f Dockerfile.os4-webapp .

echo "************************************"
echo " Test frontend container in interactive mode"
echo " -d or -it"
echo "************************************"

docker run --name="frontend-a" \
           -d \
           -e VUE_APPID_CLIENT_ID='b3adeb3b-36fc-40cb-9bc3-dd6f15047195' \
           -e VUE_APPID_DISCOVERYENDPOINT='https://us-south.appid.cloud.ibm.com/oauth/v4/a7ec8ce4-3602-42c7-8e88-6f8a9db31935/.well-known/openid-configuration' \
           -e VUE_APP_API_URL_PRODUCTS='https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/base/category/' \
           -e VUE_APP_API_URL_ORDERS='https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/base/Customer/Orders' \
           -e VUE_APP_API_URL_CATEGORIES='https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/base/category' \
           -e VUE_APP_CATEGORY_NAME='Movies' \
           -e VUE_APP_HEADLINE='Frontend A' \
           -p 8080:8081 \
           frontend:v0.0
           #"quay.io/$REPOSITORY/frontend-a:v0.0"

docker run --name="frontend-b" \
           -d \
           -e VUE_APPID_CLIENT_ID='b3adeb3b-36fc-40cb-9bc3-dd6f15047195' \
           -e VUE_APPID_DISCOVERYENDPOINT='https://us-south.appid.cloud.ibm.com/oauth/v4/a7ec8ce4-3602-42c7-8e88-6f8a9db31935/.well-known/openid-configuration' \
           -e VUE_APP_API_URL_PRODUCTS='https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/mycompany/category/' \
           -e VUE_APP_API_URL_ORDERS='https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/mycompany/Customer/Orders' \
           -e VUE_APP_API_URL_CATEGORIES='https://service-catalog.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/mycompany/category' \
           -e VUE_APP_CATEGORY_NAME='Fantasy' \
           -e VUE_APP_HEADLINE='Frontend B' \
           -p 8082:8081 \
           frontend:v0.0
            #"quay.io/$REPOSITORY/frontend-b:v0.0"

echo "************************************"
echo "Push frontend"
echo "************************************"
#docker push "quay.io/$REPOSITORY/frontend:v0.0"
