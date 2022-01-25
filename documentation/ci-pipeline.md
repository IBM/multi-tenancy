## IBM DevSecOps Reference Implementation - CI Pipeline

The CI pipelines (one for backend, one for frontend) build and push the images and run various security and code tests. Only if all checks pass, the application can be deployed to production via the CD pipelines. This assures that new versions can be deployed at any time based on business (not technical) decisions.

Overview:

* Build and push images
* Run various security checks (secret detection, image vulnerabilities, compliance)
* Run various code tests (unit tests, acceptance tests)
* Deploy services to integration/testing Kubernetes namespaces or OpenShift projects

*Step 1* 

The CI pipeline is triggered automatically after the pull request has been merged.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/001.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/002.png" /></kbd>

*Step 2* 

The CI pipeline reads the configuration.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/006.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/007.png" /></kbd>

*Step 3* 

The image is built and pushed.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/010.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/011.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/012.png" /></kbd>

*Step 4* 

The backend container is deployed to an integration/testing Kubernetes namespace or OpenShift project.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/015.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/016.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/017.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/021.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/024.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/025.png" /></kbd>

*Step 5* 

The status can be monitored in IBM DevOps Insights.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/028.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/029.png" /></kbd>

*Step 6* 

The latest successful version is stored in the inventory repo.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/032.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/033.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/034.png" /></kbd>

*Step 7* 

Evidence is collected in the evidence repo

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/035.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/036.png" /></kbd>

*Step 8* 

If the pipeline run has been successful, no issues are created in the compliance issues repo.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-2-ci-backend/037.png" /></kbd>

*Next*

After a successful run of the CI pipeline, the [CD pipeline ](cd-pull-request.md) can be run.