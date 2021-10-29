#!/bin/bash

########################################
# Nativation to verify the nginx folders
########################################
echo ""
echo ""
echo "*********************"
echo "    Navigation"
echo "*********************"
whoami
nginx stop
pwd
ls
cd /code
ls
cd ..
more ./generate_env-config.sh

########################################
# Create env-config.js file in the public folder 
# of the ngnix server, based on the environment variables
# given by the docker run -e parameter
########################################
echo ""
echo ""
echo "*********************"
echo "Get ip address"
echo "*********************"
ip addr show
echo ""
echo ""
echo "*********************"
echo "Create ./code/env-config.js"
echo "*******Exists?*********"
cd code
ls
echo "*******Delete********"
rm env-config.js
echo "*******Deleted?********"
ls
"/bin/sh" ../generate_env-config.sh > ./env-config.js
echo "*******Generated?******"
ls
########################################
# Create env-config.js file in the public folder 
# of the ngnix server
########################################
echo ""
echo ""
echo "*********************"
echo "Content ./code/env-config.js"
echo "*********************"
cd /code
more ./env-config.js

########################################
# Start ngnix server
# The configuration for the server contains also 
# 'daemon off;'')
# to replace the start command for the
# container image.
# CMD ["nginx", "-g", "daemon off;"]
########################################
echo ""
echo ""
echo "*********************"
echo "Start server"
echo "*********************"
nginx