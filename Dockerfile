FROM tomcat:10.1-jdk17-temurin

# Install MariaDB server and client for built-in database support
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-server mariadb-client dos2unix && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clean default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/examples /usr/local/tomcat/webapps/docs

# Copy schema and entrypoint script
COPY schema.sql /docker-entrypoint-initdb.d/schema.sql
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

# Deploy as both ROOT webapp and /Eventsphere context
COPY Eventsphere.war /usr/local/tomcat/webapps/ROOT.war
COPY Eventsphere.war /usr/local/tomcat/webapps/Eventsphere.war

EXPOSE 8080

CMD ["/entrypoint.sh"]
