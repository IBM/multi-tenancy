#!/bin/bash

echo "$POSTGRES_CERTIFICATE_DATA" > "$POSTGRES_CERTIFICATE_FILE_NAME"
echo ${POSTGRES_CERTIFICATE_FILE_NAME}
#cat ${POSTGRES_CERTIFICATE_FILE_NAME}
#cat /deployments/run-java.sh
sh /deployments/run-java.sh