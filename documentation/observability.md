## Observability (logging, monitoring, vulnerabilities)

**------------------**
**UNDER CONSTRUCTION**
**------------------**

Visibility of OpenShift and Kubernetes clusters on IBM Cloud can easily be enhanced by utilizing existing IBM Cloud services.  In this section, we will:

* Provide a brief summary of how [IBM Log Analysis](https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-getting-started) can be used to manage system and application logs.  We will demonstrate how the sample application's logs can be filtered or searched, identifying logs on a per tenant basis for example.
* Provide a brief summary of how [IBM Cloud Monitoring](https://cloud.ibm.com/docs/monitoring?topic=monitoring-getting-started) can be used to gain operational visibility into the performance and health of the applications (e.g. the k8s deployments for each tenant), services (e.g. Postgres instances), and platforms (e.g. the health of the entire OpenShift or IBM Kubernetes Service cluster) 
* Provide a brief summary of how the DevSecOps toolchain uses [SonarCube](https://cloud.ibm.com/docs/devsecops?topic=ContinuousDelivery-sonarqube) to help ensure quality source code, how it can be configured, and how to resolve or whitelist issues.  Explain how this relates to `Code Risk Analyzer`.
* Provide a brief summary of how the DevSecOps toolchain uses `Continuous Delivery Vulnerability Advisor` to helps avoid container vulnerabilities, and how to resolve or whitelist issues.  Explain howthis relates to `IBM Container Registry Vulnerability Advisor`.