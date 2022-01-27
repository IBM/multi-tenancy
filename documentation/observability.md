## Observability (logging, monitoring, vulnerabilities)

**------------------**
**UNDER CONSTRUCTION**
**------------------**

Visibility of OpenShift and Kubernetes clusters on IBM Cloud can easily be enhanced by utilizing existing IBM Cloud services.  In this section, we will show:

* How [IBM Log Analysis](https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-getting-started) can be used to manage system and application logs.  We will demonstrate how the sample application's logs can be filtered or searched, identifying logs on a per tenant basis for example.
* How [IBM Cloud Monitoring](https://cloud.ibm.com/docs/monitoring?topic=monitoring-getting-started) can be used to gain operational visibility into the performance and health of the applications (e.g. the k8s deployments for each tenant), services (e.g. Postgres instances), and platforms (e.g. the health of the entire OpenShift or IBM Kubernetes Service cluster) 
* How our sample DevSecOps toolchain uses [DevOps Insights](https://cloud.ibm.com/docs/ContinuousDelivery?topic=ContinuousDelivery-di_working) which can collect and analyze the results from unit tests, functional tests, and code coverage tools (using a variety of different sources).  This provides visibility of quality, as policies at specified gates in the deployment process can be set, which can halt deployments preventing risks from being released.
* How our sample DevSecOps toolchain uses [SonarCube](https://cloud.ibm.com/docs/devsecops?topic=ContinuousDelivery-sonarqube) to help ensure quality source code, how it can be configured, and how to resolve or whitelist issues.  Explain how this relates or differs from [Code Risk Analyzer](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin).
* How our sample DevSecOps toolchain uses [Continuous Delivery Vulnerability Advisor](https://cloud.ibm.com/docs/Registry?topic=Registry-registry_faq) to help avoid container vulnerabilities, and how to resolve or whitelist the issues we encountered with our sample application.