FROM tomcat:10.1-jdk17-temurin

# Clean default apps
RUN rm -rf /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/examples /usr/local/tomcat/webapps/docs

# Copy packaged Eventsphere WAR
COPY Eventsphere.war /usr/local/tomcat/webapps/Eventsphere.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
