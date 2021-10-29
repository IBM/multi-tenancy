##############################
#           BUILD
##############################
FROM docker.io/adoptopenjdk/maven-openjdk11 as BUILD
COPY src /usr/src/app/src
COPY pom.xml /usr/src/app
WORKDIR /usr/src/app
RUN mvn clean package

##############################
#           PRODUCTION
##############################
FROM fabric8/java-alpine-openjdk11-jre

ENV JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV AB_ENABLED=jmx_exporter

RUN mkdir /opt/shareclasses

# OpenShift permissions:
RUN chmod a+rwx -R /opt/shareclasses
RUN mkdir /opt/app

COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/lib/ /deployments/lib/
COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/*.jar /deployments/
COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/app/ /deployments/app/
COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/quarkus/ /deployments/quarkus/

# Get environment variables and create needed configruation
COPY ./docker-service-catalog-entry.sh ./docker-service-catalog-entry.sh
COPY ./create-service-catalog-cert.sh ./create-service-catalog-cert.sh
COPY ./cert-template ./cert-template
# Configure script to execute
RUN chmod 777 docker-service-catalog-entry.sh

EXPOSE 8080

CMD ["/bin/sh","docker-service-catalog-entry.sh"]


