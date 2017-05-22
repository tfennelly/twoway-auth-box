FROM httpd:2.4

COPY intermediate/server/server.nopass.key /usr/local/apache2/conf/server.key
COPY intermediate/server/server.crt /usr/local/apache2/conf/server.crt
COPY intermediate/certs/ca-chain.cert.pem /usr/local/apache2/conf/server-ca.crt
COPY intermediate/certs/ca-chain.cert.pem /usr/local/apache2/conf/ssl.crt/ca-bundle.crt

COPY httpd/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd/httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf