#!/bin/bash
echo "**********************************"
echo " Create cert"
echo " Create the file $CERT_FILE_NAME using the $CERT_CONTENT"
echo "**********************************"

export REAL_CERT_CONTENT="$CERT_CONTENT"

# **** Create cert file using sed
sed "s+CERT_CONTENT+$REAL_CERT_CONTENT+g" "cert-template" > $CERT_FILE_NAME

