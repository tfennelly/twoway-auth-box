#!/bin/bash

#
# See https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html and
# https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html
#

source ./env.sh

# Basic setup
rm -rf certs crl newcerts private intermediate && mkdir certs crl newcerts private intermediate
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

#
## Verify the root certificate
##openssl x509 -noout -text -in certs/ca.cert.pem
#

######################################################################
# Create the intermediate pair
######################################################################

# Prepare the directory
cd intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
cd ..

# Create the intermediate key
openssl req -new -x509 -extensions v3_ca -keyout $INTR_CA_KEY -subj "$SUBJECT_BASE-ICA" -passout pass:$PASSWD > /dev/null
# remove the passphrase from the key
openssl rsa -in $INTR_CA_KEY -out $INTR_CA_KEY -passin pass:$PASSWD
chmod 400 $INTR_CA_KEY

# Create the intermediate certificate
openssl req -config intermediate-openssl.cnf -new -sha256 \
    -key $INTR_CA_KEY \
    -subj "$SUBJECT_BASE-ICA" \
    -out $INTR_CA_CSR  
openssl ca -batch -config openssl.cnf -extensions v3_ca \
      -days 3650 -notext -md sha256 \
      -in $INTR_CA_CSR \
      -out $INTR_CA_CRT
chmod 444 $INTR_CA_CRT

# index.txt should now contain a line like the following ...
# V	270519094143Z		1000	unknown	/C=US/ST=California/O=CloudBees/OU=CDA-ICA/CN=localhost

# Verify the intermediate cert
#openssl x509 -noout -text -in $INTR_CA_CRT
#openssl verify -CAfile $ROOT_CA_CRT $INTR_CA_CRT

######################################################################
# Create the certificate chain file
######################################################################

cat $INTR_CA_CRT $ROOT_CA_CRT > $INTR_CA_CHAIN_CRT
chmod 444 $INTR_CA_CHAIN_CRT