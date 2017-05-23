#!/bin/bash

#
# See https://jamielinux.com/docs/openssl-certificate-authority/sign-server-and-client-certificates.html
#

#
# Usage:
# Supply the name as a param e.g.
# ./create-keys.sh server
#

source ./env.sh

NAME=$1
DIR=keys/$NAME

if [ -d "$DIR" ]; then
    # Creating them again doesn't work for some reason - end up with an empty
    # crt. Maybe they need to be revoked first, or something. Run ./ca-setup.sh
    # again if you really need to recreate them.
    echo "Keys for '$NAME' already issued."
    exit 1
fi

mkdir -p $DIR

PRIVATE_KEY=$DIR/$NAME.key
CSR=$DIR/$NAME.csr
CERT=$DIR/$NAME.crt
P12=$DIR/$NAME.p12
KEYSTORE=$DIR/keystore.jks
TRUSTSTORE=$DIR/truststore.jks

rm -rf $PRIVATE_KEY $CSR $CERT 

######################################################################
# Create the key
######################################################################
openssl req -new -x509 -keyout $PRIVATE_KEY -subj "$SUBJECT_BASE-$NAME" -passout pass:$PASSWD > /dev/null
openssl rsa -in $PRIVATE_KEY -out $PRIVATE_KEY -passin pass:$PASSWD
chmod 400 $PRIVATE_KEY


######################################################################
# Create the certificate
######################################################################

# The CSR
openssl req -config openssl.cnf \
      -key $PRIVATE_KEY \
      -new -sha256 \
      -subj "$SUBJECT_BASE-$NAME" \
      -out $CSR
      
# The cert
openssl ca -batch -config openssl.cnf \
      -days 375 -notext -md sha256 \
      -in $CSR \
      -out $CERT
chmod 444 $CERT

######################################################################
# Java KeyStore and TrustStore
######################################################################

openssl pkcs12 -export -out $P12 -inkey $PRIVATE_KEY -in $CERT -name "$NAME" -passout pass:$PASSWD
keytool -importkeystore -destkeystore $KEYSTORE -srckeystore $P12 -srcstoretype PKCS12 -alias $NAME -srcstorepass $PASSWD -deststorepass $PASSWD -destkeypass $PASSWD -noprompt
keytool -import -v -trustcacerts -keystore $TRUSTSTORE -noprompt -alias cacert -file $ROOT_CA_CRT -storepass $PASSWD -noprompt

######################################################################
# Print paths to generated files
######################################################################

PWD=$(pwd)
echo ""
echo "============================================================"
echo "Private key: $PWD/$PRIVATE_KEY"
echo "Certificate: $PWD/$CERT"
echo "Root CA file: $PWD/$ROOT_CA_CRT"
echo "PKCS#12 file: $PWD/$P12"
echo "Java KeyStore: $PWD/$KEYSTORE"
echo "Java TrustStore: $PWD/$TRUSTSTORE"
echo ""
echo "*** Be sure to map 'example.com' to 127.0.0.1 in your /etc/hosts file !!"
echo ""
echo "*** Note chrome can complain about example.com certs !!"
echo "*** And Firefox can complain about certs generated with an older version of openssl !!"
echo "*** Try Safari !!"
echo ""
echo ""
echo "*** Also note that you can install $PWD/$ROOT_CA_CRT as a trusted root CA"
echo "*** in your key manager (e.g. keychain on Mac)"
echo ""
echo "============================================================"
echo ""