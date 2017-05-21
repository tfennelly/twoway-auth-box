FROM httpd:2.4

COPY intermediate/private/server.key.pem.nopass /usr/local/apache2/conf/server.key
COPY intermediate/certs/server.cert.pem /usr/local/apache2/conf/server.crt
COPY intermediate/certs/ca-chain.cert.pem /usr/local/apache2/conf/server-ca.crt
COPY intermediate/certs/ca-chain.cert.pem /usr/local/apache2/conf/ssl.crt/ca-bundle.crt

COPY my-httpd.conf /usr/local/apache2/conf/httpd.conf
COPY my-httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf