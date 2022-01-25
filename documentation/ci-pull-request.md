## IBM DevSecOps Reference Implementation - CI Pull Request

Before developers can push their code into 'main', security checks need to pass and approvals need to be done first.

*Step 1* 

A developer creates a new version of README.md in the backend repo. The change is done in a developer branch.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/002.png" /></kbd>

*Step 2* 

The developer creates a pull request.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/003.png" /></kbd>

*Step 3* 

Before the pull request can be merged, security checks are performed via the 'backend pr-pipeline'.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/004.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/007.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/008.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/009.png" /></kbd>

*Step 4* 

After the security checks have passed, an approval from a second developer is required.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/011.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/012.png" /></kbd>

*Step 5* 

The second developer approves the pull request.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/013.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/015.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/016.png" /></kbd>

*Step 6* 

The pull request can now be merged.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/017.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/018.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-devsecops/cicd-1-ci-backend-pr/019.png" /></kbd>

*Next*

When the pull request has been merged, it triggers the [CI pipeline ](ci-pipeline.md).