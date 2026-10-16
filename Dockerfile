FROM tomcat:10.1-jdk17-temurin

# Clean default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/examples /usr/local/tomcat/webapps/docs

# Deploy as both ROOT webapp and /Eventsphere context
COPY Eventsphere.war /usr/local/tomcat/webapps/ROOT.war
COPY Eventsphere.war /usr/local/tomcat/webapps/Eventsphere.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
