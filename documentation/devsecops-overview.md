## IBM DevSecOps Reference Implementation

IBM uses internally a common practice and process how to implement DevSecOps. This process has been published so that IBM clients, partners and developers can use it too. See [DevSecOps Reference Implementation for Audit-Ready Compliance](https://www.ibm.com/cloud/blog/announcements/devsecops-reference-implementation-for-audit-ready-compliance-across-development-teams) for details.

This project leverages the DevSecOps reference architecture to deploy the backend and frontend containers to Kubernetes and OpenShift on the IBM Cloud.

There is IBM Cloud [documentation](https://cloud.ibm.com/docs/devsecops?topic=devsecops-tutorial-cd-devsecops) that describes how to set up the CI and CD toolchains. The documentation below adopts this information for the multi-tenancy sample application.

### Overview

There are six steps to deploy the SaaS sample application.

1. CI backend pull request: Get approval to merge backend code changes into main
2. CI backend pipeline: Pipeline to build backend image and deploy it to a staging environment for testing
3. CI frontend pull request: Get approval to merge frontend code changes into main
4. CI frontend pipeline: Pipeline to build frontend image and deploy it to a staging environment for testing
5. CD pull request: Pull request to deploy main for a specific tenant to production
6. CD pipeline: After approval deploy backend and frontend for a specific tenant to production

Check out the following documents for details:

* [CI pull request](ci-pull-request.md) related to (1) and (3)
* [CI pipeline ](ci-pipeline.md) related to (2) and (4)
* [CD pull request](cd-pull-request.md) related to (5)
* [CD pipeline](cd-pipeline.md) related to (6)

### Toolchains

There are three toolchains:

* CI for backend
* CI for frontend
* CD

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/001.png" /></kbd>

### Repos

These three repos contain the code of the microservices and the toolchains (on github.com):

* multi-tenancy
* multi-tenancy-backend
* multi-tenancy-frontend

The following repos contain state information and are shared by the three toolchains (on IBM Cloud GitLab):

* inventory
* complicance change management
* compliance issues
* evidence

The following repo contains the code for the 'out-of-the-box' security checks (on IBM Cloud GitLab):

* compliance pipelines