#!/bin/bash

#
# See https://jamielinux.com/docs/openssl-certificate-authority/sign-server-and-client-certificates.html
#

#
# Usage:
# Supply the name as a param e.g.
# ./create-keys.sh server
#

SUBJECT="/C=US/ST=California/L=San Jose/O=CloudBees/CN=localhost/OU=CDA"

NAME=$1
PRIVATE_KEY=intermediate/private/$NAME.key.pem
CSR=intermediate/csr/$NAME.csr.pem
CERT=intermediate/certs/$NAME.cert.pem

rm -rf $PRIVATE_KEY $CSR $CERT 

######################################################################
# Create the key
######################################################################
openssl genrsa -aes256 -out $PRIVATE_KEY 2048
openssl rsa -in $PRIVATE_KEY -out $PRIVATE_KEY.nopass
#chmod 400 $PRIVATE_KEY

######################################################################
# Create the certificate
######################################################################

# The CSR
openssl req -config intermediate-openssl.cnf \
      -key $PRIVATE_KEY \
      -new -sha256 \
      -subj "$SUBJECT-$NAME" \
      -out $CSR
      
# The cert
openssl ca -config intermediate-openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $CSR \
      -out $CERT
#chmod 444 $CERT

PWD=$(pwd)
echo ""
echo "============================================================"
echo "Private key: $PWD/$PRIVATE_KEY"
echo "Certificate key: $PWD/$CERT"
echo "CA chain file: $PWD/intermediate/certs/ca-chain.cert.pem"
echo "============================================================"
echo ""