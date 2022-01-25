## IBM DevSecOps Reference Implementation - CD Pipeline

The CD pipeline deploys the application to the production environments of specific tenants. For compliance reasons it needs to be triggered manually and the [promotion pipeline](cd-pull-request.md) needs to be run before.

*Step 1* 

Trigger manually the CD pipeline for certain tenant.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/002.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/003.png" /></kbd>

*Step 2* 

The CI pipeline reads the configuration. Either Kubernetes or OpenShift can be used; in a shared cluster or isolated clusters for tentants. 

The configuration is read:

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/006.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/007.png" /></kbd>

*Step 3* 

Repos are cloned:

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/005.png" /></kbd>

*Step 4* 

The delta is calculated, since only changes are deployed. Additionally security checks are performed again.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/007.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/008.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/009.png" /></kbd>

*Step 5*

The actual deployment is performed.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/010.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/011.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/012.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/014.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/020.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/021.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/018.png" /></kbd>

*Step 6*

The application can be opened.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/024.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/025.png" /></kbd>

*Step 7*

Data is collected.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/026.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/027.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/029.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/033.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/035.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/036.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/037.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/038.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/039.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-4-cd/044.png" /></kbd>