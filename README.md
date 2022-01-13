# Multi-tenancy Assets for IBM Partners to build SaaS

This repo contains multi-tenancy assets for IBM partners to build SaaS (Software as a Service).

### Project Structure

* [Project Overview](#project-overview)
* [Repositories](#repositories)
* [Getting Started](#getting-started)
* [Local Development of Services](#local-development-of-services)


## Project Overview

A key benefit of the cloud is the ability to deploy software for multiple consumers without having to install it redundantly on-premises. When software is provided as a managed service (SaaS), costs can be reduced for the deployments and the operations of applications. Additionally SaaS can be scaled and new consumers can be added easily.

In order to leverage these advantages, applications need to be designed, so that they can support multiple tenants. Often tenants are not single users, but clients of SaaS providers with their own corporate authentication mechanisms. When running SaaS for multiple tenants, it's often required to keep the workloads isolated from each other for security reasons. For example, typically separate databases are used for tenants.

At the same time common deployment and operation models are required, so that new SaaS versions can be deployed to different tenants in an unique and efficient way.

This project aims to support IBM partners to build SaaS for different platforms including Kubernetes, OpenShift, Serverless and Satellite. The used sample application, which contains two containers, is the same one for all platforms; the CI/CD mechanisms slightly differentiate between the platforms.

### Platform Options

The following diagram shows the different platform options. This repo contains the IBM Cloud platforms so far (blue rectangle). 

More options are planned to be added. For example with Satellite the SaaS application can be deployed on-premises to client data centers, but managed centrally. Additionally the same SaaS application can be deployed on other managed OpenShift services like AWS ROSA and Azure ARO.

**Serverless on IBM Cloud**

The easiest way to get started is to use serverless. The repo describes how to use IBM Code Engine to run the application logic, IBM App ID for authentication, IBM Postgres for persistence and IBM Toolchain for CI/CD. Scripts are provided to make the setup as easy as possible.

**Managed Kubernetes and OpenShift on IBM Cloud**

For more advanced cloud-native applications Kubernetes and OpenShift can be used. Compute isolation can be done either by sharing clusters and using Kubernetes namespaces/OpenShift projects or by having separate clusters for tenants. For authentication the managed services App ID and Postgres can be used, but they can also be replaced by other managed services or services running within the clusters.

For CI/CD the IBM DevSecOps reference architecture based on IBM Toolchain is used which is also the internal IBM standard and which guarantees compliance for regulated industries.

<kbd><img src="documentation/SaaS-Options.png" /></kbd>

### Sample Application

The project comes with a simple e-commerce example application. A SaaS provider might have one client selling books, another one selling shoes.

<kbd><img src="documentation/example-app.png" /></kbd>


## Repositories

This repo is the 'parent repo' including documentation and global configuration. The other three repos contain the implementation of the microservices and the serverless pipelines.

* [multi-tenancy](https://github.com/IBM/multi-tenancy) - this repo (parent repo)
    * Documentation
    * Global configuration
    * CD pipeline
    * Scripts

* [multi-tenancy-backend](https://github.com/IBM/multi-tenancy-backend) - backend microservice
    * Code
    * CI pipeline

* [multi-tenancy-frontend](https://github.com/IBM/multi-tenancy-frontend) - frontend microservice   
    * Code
    * CI pipeline

* [multi-tenancy-serverless-ci-cd](https://github.com/IBM/multi-tenancy-serverless-ci-cd) - CI and CD pipelines for serverless


## Getting Started

The easiest way to get started is to set up the sample application for two tenants on the IBM Cloud using serverless technology. The following diagram describes the serverless architecture of the simple e-commerce application which has two images (backend and frontend).

Isolated Compute:
* One frontend container per tenant
* One backend container per tenant
* One App ID instance per tenant
* One Postgres instance (with one database) per tenant

Shared CI/CD:
* One code base for frontend and backend services
* One image for frontend service
* One image for backend service
* One toolchain for all tenants (with four pipelines)

<kbd><img src="documentation/diagrams/multi-tenant-app-architecture.png" /></kbd>

Used IBM Services:
* IBM Code Engine
* IBM Container Registry
* IBM App ID
* IBM Postgres
* IBM Toolchain

Used Technologies:
* Quarkus
* Vue.js and nginx
* Bash scripts

**Initial Deployment Scripts**

Scripts and provided to set up all services and the application automatically. Follow this [step by step guide](documentation/getting-started.md) to set up everything using local bash scripts.

**Deployments of Updates via CI/CD**

Additionally pipelines are provided to re-deploy the backend and frontend services when their implementations have changed. Follow this [step by step guide](documentation/serverless-cicd.md) to set up the pipelines.


## Local Development of Services

The sample application can be used as starting point to develop your own SaaS solutions. In order to do modifications documentation is provided to change the sample services.

Check out these [local development](documentation/local-development.md) instructions how to develop, run and debug the backend and frontend services locally.