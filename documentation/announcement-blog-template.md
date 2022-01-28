* One or two sentence(s) sub-title
* Intro one or two paragraphs describing the 'why' with focus on multi-cloud
* Status: IBM Cloud done, other platforms to be done, more documentation to be done
* Team effort/authors
* Introduction 
    * [Input](https://github.com/IBM/multi-tenancy#introduction)
    * Plus personas: Dev, Ops, Sec
    * Key messages
        * Key values of this asset: 1. Starting point for SaaS, 2.  best practices, 3. shared CI/CD
        * Code, images and CI/CD are shared
        * Isolated workloads at runtime for security reasons
* Support for multiple target platforms/multi-cloud
    * Screenshot 1: [Diagram](https://github.com/IBM/multi-tenancy/raw/main/documentation/SaaS-Options.png)
    * IBM Cloud
        * Serverless
        * IKS
        * ROKS for FS-compliance
    * On-premises
    * Other public clouds: AWS, Azure
* Sample e-commerce application
    * Screenshot 2: (remove the refresh symbol and use readable title)
    * Scenario: one tenant selling books, another one selling shoes
    * Full end-to-end application including authentication and persistence
    * Sample can be used as starting point
* Value of managed services
    * ROKS, IKS and Code Engine for compute
    * Postgres, AppID, Container Registry, Toolchain
    * Replaceable 
* Automation first
    * First time experience via scripts
    * Terraform scripts to create clusters
    * Onboarding scripts and configuration
    * CI/CD pipeline for serverless
    * CI/CD pipelines for cloud-native
* Regulated industries
    * Value proposition of IBM Cloud
    * Usage of approved services and OpenShift is required
    * Based on [IBM's DevSecOps reference implementation](https://www.ibm.com/cloud/blog/announcements/devsecops-reference-implementation-for-audit-ready-compliance-across-development-teams#:~:text=The%20reference%20implementation%20of%20DevSecOps,manual%20overrides%20for%20exceptional%20situations)
    * Examples: don't push to main; detect secrets; detect vulernabilities - shift left
* Next
    * More documentation
    * Other clouds including cloud specific services
    * On-premises via Satellite
* Call to action
    * Try serverless getting started 
    * Provide feedback
