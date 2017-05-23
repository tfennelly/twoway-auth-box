FROM httpd:2.4

COPY keys/server/server.key /usr/local/apache2/conf/server.key
COPY keys/server/server.crt /usr/local/apache2/conf/server.crt
COPY certs/ca.crt /usr/local/apache2/conf/server-ca.crt
COPY certs/ca.crt /usr/local/apache2/conf/ssl.crt/ca-bundle.crt

COPY httpd/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd/httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf