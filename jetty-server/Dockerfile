FROM jetty:9.4.5-jre8

# External API
EXPOSE 8080

# Java debugger port
EXPOSE 5005

ADD target/twoway-auth-box-jetty.war /var/lib/jetty/webapps/ROOT.war

CMD java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -jar "$JETTY_HOME/start.jar"
