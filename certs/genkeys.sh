#!/bin/bash

#
# From http://nategood.com/client-side-certificate-authentication-in-ngi
#

rm ca.* server.* client.*

echo ""
echo "*** NOTE: When asked for a password/passhrase, please enter '123123'."
echo "          press enter to continue ..."
echo ""
read input_variable

# Seems like you need to make sure you don't create multiple
# with the same OU, so making sure they are unique by adding a timestamp.
TIMESTAMP=$(date +%s)

export SUBJECT_BASE="/C=US/ST=California/L=San Jose/O=Example Inc/CN=example.com/OU=CDA-$TIMESTAMP"

# Create the CA Key and Certificate for signing Client Certs
openssl genrsa -des3 -out ca.key 4096 -subj "$SUBJECT_BASE-RCA"
openssl rsa -in ca.key -out ca.key
openssl req -new -x509 -days 365 -key ca.key -out ca.crt -subj "$SUBJECT_BASE-RCA"

# Create the Server Key, CSR, and Certificate
openssl genrsa -des3 -out server.key 1024 -subj "$SUBJECT_BASE-server"
openssl rsa -in server.key -out server.key
openssl req -new -key server.key -out server.csr -subj "$SUBJECT_BASE-server"

# We're self signing our own server cert here.  This is a no-no in production.
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt

# Java KeyStore for the server. Use in the jetty-server. Note that the nginx proxy
# uses the raw .key and .crt pem files.
openssl pkcs12 -export -out server.p12 -inkey server.key -in server.crt
keytool -importkeystore -destkeystore server.keystore -srckeystore server.p12 -srcstoretype PKCS12 -noprompt

# Create the Client Key and CSR
openssl genrsa -des3 -out client.key 1024 -subj "$SUBJECT_BASE-client"
openssl rsa -in client.key -out client.key
openssl req -new -key client.key -out client.csr -subj "$SUBJECT_BASE-client"

# Sign the client certificate with our CA cert.  Unlike signing our own server cert, this is what we want to do.
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt

# Java KeyStore for the client. Not actually used by the java-client project,
# which constructs the keystore and truststore manually itself. It does this because often times
# java clients have acess to the client key and cert, but are not in a position to get at a pre-generated
# keystore and truststore.
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt
keytool -importkeystore -destkeystore client.keystore -srckeystore client.p12 -srcstoretype PKCS12 -noprompt

# Note that the server and client can use the same truststore i.e. from the same shared ca.crt.
keytool -import -v -trustcacerts -keystore truststore -noprompt -alias cacert -file ca.crt -noprompt