# multi-tenancy

**UNDER CONSTRUCTION***

Multi-tenancy samples for IBM partners who want to build SaaS software.

## Run Sample locally

To run the catalog service locally, a managed Postgres instance needs to be created first. After this you need to define four variables in local.env. See local.env.template for more:
- POSTGRES_USERNAME
- POSTGRES_PASSWORD
- POSTGRES_URL
- POSTGRES_CERTIFICATE_FILE_NAME

Additionally you need to copy the certificate file in code/service-catalog/src/main/resources/certificates.

```
$ git clone https://github.com/IBM/multi-tenancy.git
$ cd multi-tenancy
$ ROOT_FOLDER=$(pwd)
$ cp template.local.env local.env
$ cp certificate ${root_folder}/code/service-catalog/src/main/resources/
$ vi local.env
$ sh scripts/run-locally-service-catalog.sh
```

Invoke http://localhost:8081/category and http://localhost:8081/category/2/products


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

---

  * [Quarkus](https://quarkus.io/ingress)
  * [Vue.js](https://vuejs.org/)
  * [NGINX](https://www.nginx.com/)

---

  * [git 2.24.1 or higher](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  * [yarn 1.22.4 or higher](https://yarnpkg.com)
  * [Node.js v14.6.0 or higher](https://nodejs.org/en/)
  * [Apache Maven 3.6.3](https://maven.apache.org/ref/3.6.3/maven-embedder/cli.html)
  * [Quay](https://quay.io/)
  * [Tekton](https://tekton.dev/)

---

  * [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
  * [jq](https://lzone.de/cheat-sheet/jq)
  * [sed](https://en.wikipedia.org/wiki/Sed)
  * [grep](https://en.wikipedia.org/wiki/Grep)
