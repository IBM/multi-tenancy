# Multi-tenancy Assets for IBM Partners to build SaaS

This repo contains multi-tenancy assets for IBM partners to build SaaS.


### Project Structure

* [Project Overview](#project-overview)
* [Serverless Architecture](#serverless-architecture)
* [Initial Setup](#initial-setup)
* [Toolchain to update Application](#toolchain)
* [Develop Services locally](#develop-services-locally)
* [Draft Documentation](https://ibm.github.io/multi-tenancy/)


## Project Overview

The project aims to support partners to build SaaS for different platforms including Serverless, OpenShift and Satellite. As first step the repo contains an example how to run SaaS via serverless capabilities on the IBM Cloud (lower left corner).

<kbd><img src="documentation/SaaS-Options.png" /></kbd>

The project comes with a simple e-commerce example application. A SaaS provider might have one client selling books, another one selling shoes.

<kbd><img src="documentation/example-app.png" /></kbd>


## Serverless Architecture

Isolated Compute:
* One frontend container per tenant
* One backend container per tenant
* One App ID instance per tenant
* One Postgres instance (with one database) per tenant

Shared CI/CD:
* One code base for frontend and backend services
* One image for frontend service
* One image for backend service
* One toolchain for all tenants

<kbd><img src="documentation/diagrams/multi-tenant-app-architecture.png" /></kbd>


## Initial Setup

Clone the repo:

```
$ git clone https://github.com/IBM/multi-tenancy && cd multi-tenancy
$ ROOT_FOLDER=$(pwd)
```

Define the global configuration in [global.json](configuration/global.json).

Additionally define the same global configuration in [tenants-config](installapp/tenants-config). Note that this step will not be necessary sometime soon.

For each tenant define tenant-specific configuration in the folder 'configuration/tenants', for example in [tenant-a.json](configuration/tenant-a.json).

Additionally define the same configuration in [tenants-config](installapp/tenants-config). Note that this step will not be necessary sometime soon.

To create all components for the two sample tenants, run the following commands:

```
$ cd $ROOT_FOLDER/installapp
$ ibmcloud login --sso
$ sh ./ce-create-two-tenancies.sh
```

You need the following tools installed locally to run the script above:

* ibmcloud
* ibmcloud ce
* ibmcloud cdb
* Docker 
* sed
* jq
* grep
* libpq
* cURL

The script takes roughly 30 minutes. After this the URL of the frontend applications will be displayed. For both tenants the following test user can be used to log in:

User: thomas@example.com. Password: thomas4appid


## Toolchain

After you have clone this repo and changed the configuration in the folder 'configuration/tenants', create the IBM Toolchain by invoking the URL:

https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/[your-github-name]/multi-tenancy).

The pipelines can be triggered manually and they are triggered automatically when code changes occur in the Git repo.


## Develop Services locally

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
