FROM docker.io/adoptopenjdk/maven-openjdk11 as BUILD
COPY src /usr/src/app/src
CMD rm -rf /usr/src/app/src/main/resources/certificates
COPY pom.xml /usr/src/app
WORKDIR /usr/src/app
RUN mvn clean package


FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4 

ARG JAVA_PACKAGE=java-11-openjdk-headless
ARG RUN_JAVA_VERSION=1.3.8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'
RUN microdnf install curl ca-certificates ${JAVA_PACKAGE} \
    && microdnf update \
    && microdnf clean all \
    && mkdir /deployments \
    && chown 1001 /deployments \
    && chmod "g+rwX" /deployments \
    && chown 1001:root /deployments \
    && curl https://repo1.maven.org/maven2/io/fabric8/run-java-sh/${RUN_JAVA_VERSION}/run-java-sh-${RUN_JAVA_VERSION}-sh.sh -o /deployments/run-java.sh \
    && chown 1001 /deployments/run-java.sh \
    && chmod 540 /deployments/run-java.sh \
    && echo "securerandom.source=file:/dev/urandom" >> /etc/alternatives/jre/conf/security/java.security

ENV JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"

COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/lib/ /deployments/lib/
COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/*.jar /deployments/
COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/app/ /deployments/app/
COPY --from=BUILD --chown=1001 /usr/src/app/target/quarkus-app/quarkus/ /deployments/quarkus/

COPY ./docker-service-catalog-entry.sh ./docker-service-catalog-entry.sh
RUN chmod 777 docker-service-catalog-entry.sh
ENV POSTGRES_CERTIFICATE_FILE_NAME /cloud-postgres-cert
RUN touch $POSTGRES_CERTIFICATE_FILE_NAME
RUN chmod 777 $POSTGRES_CERTIFICATE_FILE_NAME

EXPOSE 8081
USER 1001

ENTRYPOINT ["/bin/sh","docker-service-catalog-entry.sh"]