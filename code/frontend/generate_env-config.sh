#!/bin/bash
########################################
# Create a file based on the environment variables
# given by the dockerc run -e parameter
########################################
cat <<EOF
// App ID
window.VUE_APPID_CLIENT_ID="${VUE_APPID_CLIENT_ID}"
window.VUE_APPID_DISCOVERYENDPOINT="${VUE_APPID_DISCOVERYENDPOINT}"
// Application URLs
window.VUE_APP_API_URL_PRODUCTS="${VUE_APP_API_URL_PRODUCTS}"
window.VUE_APP_API_URL_CATEGORIES="${VUE_APP_API_URL_CATEGORIES}"
window.VUE_APP_API_URL_ORDERS="${VUE_APP_API_URL_ORDERS}"
// Configurations
window.VUE_APP_CATEGORY_NAME="${VUE_APP_CATEGORY_NAME}"
window.VUE_APP_HEADLINE="${VUE_APP_HEADLINE}"
EOF