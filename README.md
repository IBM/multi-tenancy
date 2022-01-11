# Multi-tenancy Assets for IBM Partners to build SaaS

This repo contains multi-tenancy assets for IBM partners to build SaaS.
.

### Project Structure

* [Project Overview](#project-overview)
* [Repositories](#repositories)
* [Serverless Architecture](#serverless-architecture)
* [Initial Setup](#initial-setup)
* [Toolchain to update Application](#toolchain)
* [Develop Services locally](#develop-backend-service-locally)
* [Draft Documentation](https://ibm.github.io/multi-tenancy/)


## Project Overview

The project aims to support partners to build SaaS for different platforms including Serverless, OpenShift and Satellite. As first step the repo contains an example how to run SaaS via serverless capabilities on the IBM Cloud (lower left corner).

<kbd><img src="documentation/SaaS-Options.png" /></kbd>

The project comes with a simple e-commerce example application. A SaaS provider might have one client selling books, another one selling shoes.

<kbd><img src="documentation/example-app.png" /></kbd>

## Repositories

This repo is the 'parent repo' including documentation and global configuration.

* [multi-tenancy](https://github.com/IBM/multi-tenancy) - parent repo
1) Documentation
2) Global configuration
3) CD pipeline
4) Scripts

* [multi-tenancy-backend](https://github.com/IBM/multi-tenancy-backend) - backend microservice
1) Code
2) CI pipeline

* [multi-tenancy-frontend](https://github.com/IBM/multi-tenancy-frontend) - frontend microservice
1) Code
2) CI pipeline

* [multi-tenancy-serverless-ci-cd](https://github.com/IBM/multi-tenancy-serverless-ci-cd) - CI and CD pipelines for serverless


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

### Step 1: Clone the repositories:

```sh
$ git clone https://github.com/IBM/multi-tenancy 
$ git clone https://github.com/IBM/multi-tenancy-backend
$ git clone https://github.com/IBM/multi-tenancy-frontend && cd multi-tenancy
$ ROOT_FOLDER=$(pwd)
```

### Step 2 : Verify the prerequisites for running the installation

```sh
$ cd $ROOT_FOLDER/installapp
$ sh ./ce-check-prerequisites.sh
```
You need the following tools installed locally to run the script above:

* ibmcloud
* ibmcloud plugin code-engine
* ibmcloud plugin cloud-databases
* ibmcloud plugin container-registry
* Docker
* [sed](https://en.wikipedia.org/wiki/Sed)
* [jq](https://lzone.de/cheat-sheet/jq)
* [grep](https://en.wikipedia.org/wiki/Grep)
* [libpq (psql)](https://www.postgresql.org/docs/9.5/libpq.html) 
* [cURL](https://curl.se/)

### Step 3: Define the configuration for the tenants you want to install

Define the global configuration in [global.json](configuration/global.json).

Additionally define the same global configuration in [tenants-config](installapp/tenants-config). Note that this step will not be necessary sometime soon.

For each tenant define tenant-specific configuration in the folder 'configuration/tenants', for example in [tenant-a.json](configuration/tenant-a.json).

Additionally define the same configuration in [tenants-config](installapp/tenants-config). Note that this step will not be necessary sometime soon.

### Step 5 : Start the installation

To create all components for the two sample tenants configurations, run the following commands:

```sh
$ ibmcloud login --sso
$ sh ./ce-create-two-tenancies.sh
```

The script takes roughly 30 minutes. After this the URL of the frontend applications will be displayed. For both tenants the following test user can be used to log in:

User: thomas@example.com. Password: thomas4appid


### Details initial installation bash scripts

There are three bash script used for the initial installation. The following diagram shows the simplified dependencies of the bash scripts use to create two tenants on an application on IBM Cloud in Code Engine.

![](documentation/images/simplified-overview-bash-scripts-installation.png)

The scripts creating two tenants:

* Two Code Engine projects with two applications one frontend and one backend.
* Two App ID instance to provide a basic authentication and authorization for the two tenants.
* Two Postgres databases for the two tenants.

The table contains the script and the responsibility of the scripts.

| Script | Responsibility |
|---|---|
| `ce-create-two-tenancies.sh` | Build the container images therefor it invokes the bash script `ce-build-images-ibm-docker.sh` and uploads the images to the IBM Cloud container registry. It also starts the creation of the tenant application instance, therefor it invokes the bash script `ce-install-application.sh` twice. |
| `ce-build-images-ibm-docker.sh` | Creates two container images based on the given parameters for the backend and frontend image names. |
| `ce-install-application.sh` | Creates and configures a `Code Engine project`. The configuration of the Code Engine project includes the `creation of the application`, the `IBM Cloud Container Registry access` and `secrets` for the needed parameter for the running applications. It creates an `IBM Cloud App ID instance` and configures this instance that includes the `application`, `redirects`, `login layout`, `scope`, `role` and `user`. It also creates and `IBM Cloud Postgres` database instance and creates the needed example data with tables inside the database.|


## Toolchain

After you have clone this repo and changed the configuration in the folder 'configuration/tenants', create the IBM Toolchain by invoking the URL:

https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/[your-github-name]/multi-tenancy).

The pipelines can be triggered manually and they are triggered automatically when code changes occur in the Git repo.


## Develop Backend Service locally

To run the backend service locally, a [managed Postgres](https://cloud.ibm.com/databases/databases-for-postgresql/create) instance needs to be created first. After this you need to define four variables in local.env. See local.env.template for more:
- POSTGRES_USERNAME
- POSTGRES_PASSWORD
- POSTGRES_URL
- POSTGRES_CERTIFICATE_FILE_NAME

Additionally you need to copy the certificate file in code/service-catalog/src/main/resources/certificates. As file name use the Postgres username.

For the authentication a [App ID](https://www.ibm.com/cloud/app-id) instance is required. Copy the two settings in local.env:
- APPID_CLIENT_ID (note: this is not the client id in the secrets, but in the application settings)
- APPID_DISCOVERYENDPOINT

For IBMers only: You can re-use existing services by using these [configuration](https://github.ibm.com/niklas-heidloff/multi-tenancy-credentials) files.

```
$ git clone https://github.com/IBM/multi-tenancy.git
$ git clone https://github.com/IBM/multi-tenancy-backend.git
$ cd multi-tenancy
$ ROOT_FOLDER=$(pwd)
$ cp certificate ${root_folder}/code/service-catalog/src/main/resources/certificates/
$ cp template.local.env local.env
$ vi local.env
```

Run the backend service locally via Maven:

```
$ sh scripts/run-locally-backend.sh
```

Or run the backend service locally via container (podman):

```
$ sh scripts/run-locally-container-backend.sh
```

Invoke http://localhost:8081/category/2/products.

(User: thomas@example.com. Password: thomas4appid)
