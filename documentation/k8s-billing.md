## OpenShift/IBM Kubernetes Service Billing

**------------------**
**UNDER CONSTRUCTION**
**------------------**

In this section we will explain techniques which can be used to track the relative resource consumption of individual namespaces/projects, when each tenant is deployed to a shared OpenShift/IBM Kubernetes cluster.  We will describe how to achieve this on a per namespace/project level with [IBM Cloud Monitoring](https://cloud.ibm.com/docs/monitoring?topic=monitoring-getting-started).  As all tenants share the same OpenShift/IBM Kubernetes cluster, standard IBM Cloud billing can be used to see this fixed cost.

Each tenant will have their own service instances for Postgres and AppId, so we will show how standard IBM Cloud billing can be used to see costs per service instance (or resource group, if we decide to organise the services in this way).  If however the business prefers to use Postgres in a multi-tenant way, we will also describe how to use [IBM Cloud Monitoring](https://cloud.ibm.com/docs/monitoring?topic=monitoring-getting-started) to monitor Postgres 'per shema'.

