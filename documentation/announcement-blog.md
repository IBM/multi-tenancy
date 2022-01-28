## New Open-Source DevSecOps asset helps build SaaS

When software is provided as a managed service (SaaS), using a multi-tenant approach helps minimise costs for the deployments and operations of each tenant.  In order to leverage these advantages, applications need to be designed so that they can be deployed to support multiple tenants, while maintaining isolation for security reasons.  At the same time, common deployment and operation models are required so that new SaaS versions can be deployed to existing tenants, or to onboard new tenants, in a reliable and efficient way.

A new [open-source project](https://github.com/IBM/multi-tenancy) aims to support a DevSecOps approach to building multi-tenant SaaS for different platforms including Kubernetes, Red Hat OpenShift, Serverless, Satellite, AWS and Azure.  The asset includes DevSecOps toolchains to automate the steps for deploying a sample cloud native application (customized by parameters for each tenant) to a common platform, and create per-tenant cloud services for database and authentication.

The initial release uses IBM Cloud Tekton toolchains to deploy SaaS to IBM Code Engine (serverless), Red Hat OpenShift on IBM Cloud or IBM Kubernetes Service on IBM Cloud.  We have plans to extend the deployment to support multi-cloud using OpenShift, including Azure ARO and AWS ROSA.

This asset has been created by IBM's Build Labs:

* [Niklas]()
* [Thomas]()
* [Alain]()
* [Adam]()

### Introduction

Organizations offering SaaS will need to deliver rapidly and often, while maintaining a strong security posture and continuous state of audit-readiness.  Achieving this goal involves several teams including developers, IT operations and security.  DevSecOps integrates a set of security and compliance controls and makes application and infrastructure security a shared responsibility for all these teams, and automatically bakes in security at every phase of the software development lifecycle, bringing speed and security.  This is of particulalr importantce for SaaS where the challenges and benefits are a factor of the number of tenants!

The project provides a starting point for learning how to create an application which is ready for SaaS, using best practices for DevSecOps such as detecting code or container vulnerabilities, and using Continuous Integration and Continuous Delivery (CI/CD) pipelines to automate deployments.  The key value of this asset is that it shows how to reuse the same application code, containers and CI/CD, with the flexibility to deploy to a dedicated or shared Kubernetes cluster, while maintaining isolation and secuirty.

### Support for multiple platforms

The following diagram shows the different deployment platform options so far (highlighted by the blue rectangle).  The future addition of IBM Cloud Satellite will allow the SaaS application to be deployed on-premises at client data centers, while still taking advantage of an OpenShift Cluster managed by IBM Cloud.  Additionally, the same SaaS application could be deployed on other managed OpenShift services like AWS ROSA and Azure ARO.

The easiest way to get started is with serverless, using the fully managed IBM Code Engine Kubernetes platform to run the application.  For more advanced cloud-native applications, a dedicated Kubernetes or OpenShift cluster can be used.  Compute isolation can be achieved with a shared clusters using Kubernetes namespaces/OpenShift projects, or by having dedicated clusters for each SaaS tenant.

[IBM Cloud App ID]() is used to add authentication to the sample app, [IBM Cloud Databases for Postgres]() is used for persistence, and [IBM Continuous Delivery]() is used to setup the Toolchain for CI/CD.  The CI/CD is based in an [IBM DevSecOps reference architecture](https://www.ibm.com/cloud/blog/announcements/devsecops-reference-implementation-for-audit-ready-compliance-across-development-teams), guaranteeing compliance for regulated industries.

<kbd><img src="https://github.com/IBM/multi-tenancy/raw/main/documentation/SaaS-Options.png" /></kbd>

### Sample e-commerce application

A sample e-commerce application is provided, which is deployed as two containers.  A frontend web application created with Vue.js displays a catalog of products.  The data for the catalog is provided by a backend microservice.  Configuration properties are used extensively to customize both the frontend and backend at deployment time, including titles, connection details for the database and authentication service etc.  This means the same e-commerce sample application can easily be used for multiple tenants, perhaps one selling books, the other shoes.

### Automation first

Everything in this project embraces automation and the asset provides a variety of approaches to deploy SaaS.

You can get started quickly by using bash scripts to create sample application container images, deploy and configure Postgres and AppID cloud services, then deploy multiple applications per configured tenant.  On-boarding additional tenants is as simple as adding to the configuration file, and running a single bash script.

When you're ready to embrace DevOps. a simple toolchain is provided with CI/CD pipelines for build and deployment of both frontend and backend containers to IBM Code Engine.

When you're ready to try with IBM Kubernetes Service or OpenShift, Terraform templates are provided to automate the cluster deployment on IBM Cloud.  A more comprehensive toolchain is used for deployment to a Kubernetes cluster, using a DevSecOps approach.  Multiple pipelines are included:

* Pull Request (PR) Pipeline: This is typically triggered by a developer when they want to conribute source code from their own branch, by creating a merge or pull request (PR) in the application repository.  The pipeline runs unit test and static scans on the source code and second developer must approve the PR.
* Continuous Integration (CI) Pipeline: When a change is merged to the main branch of the application repository, the CI Pipeline runs tests on the source code and deployment manifests to detect secrets or security risks, as well as scanning the container images for vulnerabilities.  Unit and code coverage tests can also be incorporated.  The CI pipeline builds the binary artifacts (containers), uploads them to the IBM Container Registry and deploys them to the runtime environment as an integration test.  The CI Pipeline also generates metadata about the build artifacts and stores this in another repository, for purposes of compliance and audit.
* Promotion (CD) Pipeline: This is manually triggered to create a new merge / PR to push the latest code changes from the source (main) branch to the target branch of a particular tenant.
* Continuous Deployment (CD) Pipeline: The CD pipeline is used to deploy the application to the production environments of specific tenant (i.e. a tenant specifc namespace in a Kubernetes cluster).  For compliance reasons it needs to be triggered manually, after the merge is completed from the previous Promotion Pipeline.

### Ready for regulated industries

WORK IN PROGRESS

### What's next?

Our project is constantly evolving.  You can expect more supported platforms including IBM Cloud Satellite, and other public clouds including support for their native database and authentication services.  We still have some work to do on the documentation, e.g. explaining how to observe multi-tenant runtime logs, and understand how much cloud resource each tenant is consuming, to help calculate the bills.

In the meantime, we invite you to explore the [repo](https://github.com/IBM/multi-tenancy) and give it a try.  Why not start by using our most simple script based approach with IBM Code Engine, and see for yourself how easy it is is to be a SaaS provider!  If you have feedback or comments, please don't hesitate to get in touch.