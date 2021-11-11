# multi-tenancy

**UNDER CONSTRUCTION***

Multi-tenancy samples for IBM partners who want to build SaaS software.

## Run Pipeline to deploy Catalog Service

[Create Catalog Service on Code Engine](https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/ibm/multi-tenancy)


## Run Sample locally

To run the catalog service locally, a [managed Postgres](https://cloud.ibm.com/databases/databases-for-postgresql/create) instance needs to be created first. After this you need to define four variables in local.env. See local.env.template for more:
- POSTGRES_USERNAME
- POSTGRES_PASSWORD
- POSTGRES_URL
- POSTGRES_CERTIFICATE_FILE_NAME

Additionally you need to copy the certificate file in code/service-catalog/src/main/resources/certificates. As file name use the Postgres username.

For the authentication a [App ID](https://www.ibm.com/cloud/app-id) instance is required. Copy the two settings in local.env:
- APPID_CLIENT_ID
- APPID_DISCOVERYENDPOINT

For IBMers only: You can re-use existing services by using these [configuration](https://github.ibm.com/niklas-heidloff/multi-tenancy-credentials) files.

```
$ git clone https://github.com/IBM/multi-tenancy.git
$ cd multi-tenancy
$ ROOT_FOLDER=$(pwd)
$ cp certificate ${root_folder}/code/service-catalog/src/main/resources/certificates/
$ cp template.local.env local.env
$ vi local.env
```

Run the catalog service and frontend locally via Maven and Webpack:

```
$ sh scripts/run-locally-service-catalog.sh
$ sh scripts/run-locally-frontend.sh
```

Or run the catalog service locally via container (podman):

```
$ sh scripts/run-locally-container-service-catalog.sh
$ sh scripts/run-locally-container-frontend.sh
```

Open http://localhost:8080 or invoke http://localhost:8081/category and http://localhost:8081/category/2/products.

User: thomas@example.com. Password: thomas4appid

This project is documented **[here](https://ibm.github.io/multi-tenancy/)**.

## Target architecture `serverless`overview:

* Just a single tenant. This is a simplified diagram containing the used elements and dependencies.

![](documentation/images/Multi-tenancy-serverless.png)

## Technology Used

The example ecommerce mircorservices application is build on following `technologies/services/tools/frameworks`.

  * [Microservices architecture](https://en.wikipedia.org/wiki/Microservices)
  * [OpenID Connect](https://openid.net/connect/)
  * [MicroProfile](https://microprofile.io/)

---

  * [IBM Cloud Code Engine](https://cloud.ibm.com/docs/codeengine?topic=codeengine-about)
  * [Postgres](https://cloud.ibm.com/databases/databases-for-postgresql/create)
  * [AppID](https://www.ibm.com/de-de/cloud/app-id)
  * [Toolchain](https://cloud.ibm.com/docs/ContinuousDelivery?topic=ContinuousDelivery-toolchains_getting_started)
  * [IBM Cloud Container Registry](https://cloud.ibm.com/registry/catalog)

---

  * [Quarkus](https://quarkus.io/ingress)
  * [Vue.js](https://vuejs.org/)
  * [NGINX](https://www.nginx.com/)

---

  * [git 2.24.1 or higher](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  * [yarn 1.22.4 or higher](https://yarnpkg.com)
  * [Node.js v14.6.0 or higher](https://nodejs.org/en/)
  * [npm](https://www.npmjs.com/)
  * [Apache Maven 3.6.3](https://maven.apache.org/ref/3.6.3/maven-embedder/cli.html)
  * [Quay](https://quay.io/) 
  * [Tekton](https://tekton.dev/)

---
  
  * [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
  * [jq](https://lzone.de/cheat-sheet/jq)
  * [sed](https://en.wikipedia.org/wiki/Sed)
  * [grep](https://en.wikipedia.org/wiki/Grep)
  * [libpq](https://github.com/lpsmith/postgresql-libpq)
  * [cURL](https://curl.se/)
  * [Docker](https://www.docker.com/) (deploy to IBM Cloud Container Registry)
  * [Podman](https://podman.io/)
