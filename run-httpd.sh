#!/bin/bash

cd httpd
rm -rf certs
mkdir certs
cp ../certs/server.* certs 
cp ../certs/ca.crt certs 

docker build -t myhttpd .
docker run -p 443:443 myhttpd

cd ..