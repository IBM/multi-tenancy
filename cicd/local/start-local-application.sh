#!/bin/bash
# https://scriptingosx.com/2020/03/macos-shell-command-to-create-a-new-terminal-window/

export HOME_PATH=$(pwd)
echo "HOME_PATH: " $HOME_PATH

# bash scripts
export WEB_APP_TENANT_A="$HOME_PATH/start_vue-tenant_A.sh"
export SERVICE_CATALOG_A="$HOME_PATH/start_service-catalog_A.sh"

# urls
export WEB_APP_TENANT_A_URL="http://localhost:8080"

echo "************************************"
echo "    Configure for execution"
echo "************************************"
chmod 755 $WEB_APP_TENANT_A
chmod 755 $SERVICE_CATALOG_A

echo "************************************"
echo "    Open Terminals"
echo "************************************"

open -a Terminal $WEB_APP_TENANT_A 
open -a Terminal $SERVICE_CATALOG_A 

echo "************************************"
echo "    Open Browser"
echo "************************************"
open -a "Google Chrome" $WEB_APP_TENANT_A_URL
