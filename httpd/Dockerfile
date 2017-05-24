FROM httpd:2.4

COPY certs/server.key /usr/local/apache2/conf/server.key
COPY certs/server.crt /usr/local/apache2/conf/server.crt
COPY certs/ca.crt /usr/local/apache2/conf/server-ca.crt
COPY certs/ca.crt /usr/local/apache2/conf/ssl.crt/ca-bundle.crt

COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf