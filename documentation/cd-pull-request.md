## IBM DevSecOps Reference Implementation - CD Pull Request

In order to deploy a new version for a specific tenant, a pull request (which is the same as a merge request in GitLab) has to be created and merged. The pull request merges the latest version in the main branch of the inventory to the tenant specific branches in the inventory.

*Step 1* 

Trigger manually the CD promotion trigger pipeline.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/005.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/006.png" /></kbd>

*Step 2* 

A pull request is created.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/008.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/009.png" /></kbd>

*Step 3* 

In the pull request the priority and assignee has to be defined. After this it can be saved and merged.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/010.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/012.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-3-cd-promotion/014.png" /></kbd>

*Next*

After the pull request has been merged, the actual [CD pipeline ](cd-pipeline.md) can be triggered.