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

* [CI pull request](ci-pull-request.md)
* [CI pipeline ](ci-pipeline.md)
* [CD pull request](cd-pull-request.md)
* [CD pipeline](cd-pipeline.md)




