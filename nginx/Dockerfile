FROM ubuntu:16.04

# For the `perl_modules` extension.                                                                       
RUN apt-get update && apt-get install -y nginx nginx-extras liburi-encode-perl

# Overwrite default nginx configuration                                                                   
COPY nginx.conf /etc/nginx/

COPY nginx.conf /etc/nginx/conf.d/
COPY certs/server.crt         /etc/nginx/certs/
COPY certs/server.key         /etc/nginx/certs/
COPY certs/ca.crt             /etc/nginx/certs/

COPY SetCertHeader.pm       /usr/share/nginx/perl/lib/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]