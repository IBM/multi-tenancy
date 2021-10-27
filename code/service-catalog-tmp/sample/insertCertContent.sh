#!/bin/bash

export REAL_CERT_CONTENT="Hi Karim, that's the content ;-)"

# **** Create cert
sed "s+CERT_CONTENT+$REAL_CERT_CONTENT+g" "cert-template" > ./real_cert
