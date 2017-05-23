#!/bin/bash

cd nginx
rm -rf certs
mkdir certs
cp ../certs/server.* certs 
cp ../certs/ca.crt certs 

docker-compose down
docker-compose build
docker-compose up

cd ..