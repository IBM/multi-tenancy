## Backend Microservice Container

[Quarkus](https://quarkus.io/) is a great way to build microservices with Java. It doesn't require a lot of memory, it starts very fast, it comes with very popular Java libraries and has a big community.

When creating new Quarkus projects via the CLI, Maven or the UI, various Dockerfiles are created automatically. In this project the generated Dockerfile is used which is based on ubi8/ubi-minimal and uses the Hotspot JVM.

Check out the [Dockerfile](https://github.com/IBM/multi-tenancy-backend/blob/474954508eb2d64da08cbe333f0fd2d4849cd741/Dockerfile).

Description:

* The image has not been optimized, for example by using OpenJ9.
* The generated Dockerfile is roughly from mid 2020 and uses old versions. As a result the IBM vulnerability scans show errors which need to be fixed by using newer versions.
* The image doesn't use root users so that it can be run on OpenShift.
* The Dockerfile uses two stages. The first stage uses Maven to build the application. This stage should be updated as well.
* The image listens to port 8081.
* The image can be configured with various environment variables to access Postgres and AppID. See the [deployment.yaml](https://github.com/IBM/multi-tenancy-backend/blob/474954508eb2d64da08cbe333f0fd2d4849cd741/deployments/kubernetes.yml#L19-L48) for details.
* The Postgres certificate is not copied on the image for security reasons. Instead it is copied on the container directory '/cloud-postgres-cert' via a bash [script](https://github.com/IBM/multi-tenancy-backend/blob/474954508eb2d64da08cbe333f0fd2d4849cd741/docker-service-catalog-entry.sh).