#!/bin/bash

#
# From http://nategood.com/client-side-certificate-authentication-in-ngi
#

rm ca.* server.* client.*

# echo ""
# echo "*** NOTE: When asked for a password/passhrase, please enter '123123'."
# echo "          press enter to continue ..."
# echo ""
# read input_variable

# Seems like you need to make sure you don't create multiple
# with the same OU, so making sure they are unique by adding a timestamp.
TIMESTAMP=$(date +%s)
export DAYS=${DAYS:-365}

export PASSPHRASE=123123
export SUBJECT_BASE="/C=US/ST=California/L=San Jose/O=Example Inc/CN=example.com/OU=CDA-$TIMESTAMP"

# Create the CA Key and Certificate for signing Client Certs
echo "Create the CA Key and Certificate for signing Client Certs"
echo "generating ca.key ... "
openssl genrsa -des3 -passout env:PASSPHRASE -out ca.key 4096 -subj "$SUBJECT_BASE-RCA"
echo "removing password for ca.key ... "
openssl rsa -in ca.key -passin env:PASSPHRASE -out ca.key
echo "creating a self signed CA certificate instead of a certificate request ... for $DAYS days"
openssl req -new -x509 -days $DAYS -passin env:PASSPHRASE -key ca.key -out ca.crt -subj "$SUBJECT_BASE-RCA"

# Create the Server Key, CSR, and Certificate
echo "generating servey.key ... "
openssl genrsa -des3 -passout env:PASSPHRASE -out server.key 1024 -subj "$SUBJECT_BASE-server"
echo "removing password for server.key ... "
openssl rsa -in server.key -passin env:PASSPHRASE -out server.key
echo "creating a server certificate signing request ... "
openssl req -new -passin env:PASSPHRASE -key server.key -out server.csr -subj "$SUBJECT_BASE-server"

# We're self signing our own server cert here.  This is a no-no in production.
echo "creating a self signed server certificate ... "
openssl x509 -req -days $DAYS -passin env:PASSPHRASE -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt

# Java KeyStore for the server. Use in the jetty-server. Note that the nginx proxy
# uses the raw .key and .crt pem files.
echo "exporting server.crt to server.p12 format ... "
openssl pkcs12 -export -out server.p12 -passin env:PASSPHRASE -passout env:PASSPHRASE -inkey server.key -in server.crt

# Create the Client Key and CSR
openssl genrsa -des3 -passout env:PASSPHRASE -out client.key 1024 -subj "$SUBJECT_BASE-client"
openssl rsa -in client.key -passin env:PASSPHRASE -out client.key
openssl req -new -passin env:PASSPHRASE -key client.key -out client.csr -subj "$SUBJECT_BASE-client"

# Sign the client certificate with our CA cert.  Unlike signing our own server cert, this is what we want to do.
openssl x509 -req -days $DAYS -passin env:PASSPHRASE -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt

# Java KeyStore for the client. Not actually used by the java-client project,
# which constructs the keystore and truststore manually itself. It does this because often times
# java clients have acess to the client key and cert, but are not in a position to get at a pre-generated
# keystore and truststore.
echo "generating client.p12 ...."
openssl pkcs12 -export -out client.p12 -passin env:PASSPHRASE -passout env:PASSPHRASE -inkey client.key -in client.crt

# # Note that the server and client can use the same truststore i.e. from the same shared ca.crt.
keytool -importkeystore -destkeystore server.keystore -srckeystore server.p12 -srcstoretype PKCS12 -noprompt
keytool -importkeystore -destkeystore client.keystore -srckeystore client.p12 -srcstoretype PKCS12 -noprompt
keytool -import -v -trustcacerts -keystore truststore -noprompt -alias cacert -keypass $PASSPHRASE -file ca.crt -noprompt