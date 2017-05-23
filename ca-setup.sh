#!/bin/bash

#
# See https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
#

source ./env.sh

# Basic setup
rm -rf certs crl newcerts private keys && mkdir certs crl newcerts private keys
chmod 700 private
rm index.* serial*
touch index.txt
echo 1000 > serial

######################################################################
# Create the root CA
######################################################################

# Create the root key and cert
openssl req -new -x509 -extensions v3_ca -keyout $ROOT_CA_KEY -out $ROOT_CA_CRT -days 7300 -config ./openssl.cnf -subj "$SUBJECT_BASE-RCA" -passout pass:$PASSWD
# remove the passphrase from the key
openssl rsa -in $ROOT_CA_KEY -out $ROOT_CA_KEY -passin pass:$PASSWD
chmod 400 $ROOT_CA_KEY
chmod 444 $ROOT_CA_CRT
