#!/bin/bash

docker build -t myhttpd .
docker run -p 443:443 myhttpd