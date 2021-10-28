#!/bin/bash
export HOME_PATH_NEW=$(pwd)
export PATH_TO_CODE="Downloads/dev/multi-tenancy"

echo "************************************"
echo " Home path: $HOME_PATH_NEW"
echo "************************************"
export APP_NAME=frontend
export WEB_APP="$PATH_TO_CODE/code/$APP_NAME"
export MESSAGE="Starting 'Tenant-A Web-Application'"

echo "************************************"
echo "    $MESSAGE"
echo "************************************"

cd $WEB_APP
npm install
npm run serve