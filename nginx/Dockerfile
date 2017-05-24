# build from the official Nginx image
FROM nginx:1.13.0

RUN apt-get update && apt-get install -y curl

COPY nginx.conf /etc/nginx/conf.d/
COPY certs/server.crt         /etc/nginx/certs/
COPY certs/server.key         /etc/nginx/certs/
COPY certs/ca.crt             /etc/nginx/certs/