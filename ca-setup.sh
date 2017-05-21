#!/bin/bash

#
# See https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html and
# https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html
#

SUBJECT="/C=US/ST=California/L=San Jose/O=CloudBees/CN=localhost/OU=CDA"

# Basic setup
rm -rf certs crl newcerts private intermediate && mkdir certs crl newcerts private intermediate
chmod 700 private
rm index.* serial*
touch index.txt
echo 1000 > serial

######################################################################
# Create the root CA
######################################################################

# Create the root key
openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem

# Create the root certificate
openssl req -config openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -subj "$SUBJECT-RCA" \
      -out certs/ca.cert.pem
chmod 444 certs/ca.cert.pem

# Verify the root certificate
#openssl x509 -noout -text -in certs/ca.cert.pem

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

# Create the intermediate key
cd ..
openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
chmod 400 intermediate/private/intermediate.key.pem

# Create the intermediate certificate
openssl req -config intermediate-openssl.cnf -new -sha256 \
    -key intermediate/private/intermediate.key.pem \
    -subj "$SUBJECT-ICA" \
    -out intermediate/csr/intermediate.csr.pem      
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem
chmod 444 intermediate/certs/intermediate.cert.pem

# index.txt should now contain a line like the following ...
# V	270519094143Z		1000	unknown	/C=US/ST=California/O=CloudBees/OU=CDA-ICA/CN=localhost

# Verify the intermediate cert
#openssl x509 -noout -text -in intermediate/certs/intermediate.cert.pem
#openssl verify -CAfile certs/ca.cert.pem intermediate/certs/intermediate.cert.pem

######################################################################
# Create the certificate chain file
######################################################################

cat intermediate/certs/intermediate.cert.pem certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
chmod 444 intermediate/certs/ca-chain.cert.pem