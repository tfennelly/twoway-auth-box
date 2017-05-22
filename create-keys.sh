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
DIR=intermediate/$NAME

if [ -d "$DIR" ]; then
    # Creating them again doesn't work for some reason - end up with an empty
    # crt. Maybe they need to be revoked first, or something. Run ./ca-setup.sh
    # again if you really need to recreate them.
    echo "Keys for '$NAME' already issued."
    exit 1
fi

mkdir -p $DIR

CA_CERT=intermediate/certs/ca-chain.cert.pem
PRIVATE_KEY=$DIR/$NAME.key
PRIVATE_KEY_NOPASS=$DIR/$NAME.nopass.key
CSR=$DIR/$NAME.csr
CERT=$DIR/$NAME.crt
P12=$DIR/$NAME.p12
KEYSTORE=$DIR/keystore.jks
TRUSTSTORE=$DIR/truststore.jks

rm -rf $PRIVATE_KEY $CSR $CERT 

######################################################################
# Create the key
######################################################################
openssl genrsa -aes256 -out $PRIVATE_KEY 2048
openssl rsa -in $PRIVATE_KEY -out $PRIVATE_KEY_NOPASS
chmod 400 $PRIVATE_KEY $PRIVATE_KEY_NOPASS

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
chmod 444 $CERT

######################################################################
# Java KeyStore and TrustStore
######################################################################

openssl pkcs12 -export -out $P12 -inkey $PRIVATE_KEY -in $CERT -certfile $CA_CERT -name "$NAME"
keytool -importkeystore -destkeystore $KEYSTORE -srckeystore $P12 -srcstoretype PKCS12 -alias $NAME
keytool -import -v -trustcacerts -keystore $TRUSTSTORE -noprompt -alias cacert -file $CA_CERT

######################################################################
# Print paths to generated files
######################################################################

PWD=$(pwd)
echo ""
echo "============================================================"
echo "Private key: $PWD/$PRIVATE_KEY"
echo "Private key - no password: $PWD/$PRIVATE_KEY_NOPASS"
echo "Certificate: $PWD/$CERT"
echo "CA chain file: $PWD/$CA_CERT"
echo "PKCS#12 file: $PWD/$P12"
echo "Java KeyStore: $PWD/$KEYSTORE"
echo "Java TrustStore: $PWD/$TRUSTSTORE"
echo "============================================================"
echo ""