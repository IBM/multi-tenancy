# Simple Pipelines to update Serverless Application

In order to update the backend and frontend containers on Code Engine, simple CI/CD pipelines are provided.

* pipeline-backend: Builds the backend image and triggers the  deployment pipelines for all tenants
* pipeline-backend-tenant: Deploys the backend container for one tenant
* pipeline-frontend: Builds the frontend image and triggers the  deployment pipelines for all tenants
* pipeline-frontend-tenant: Deploys the frontend container for one tenant

The pipelines will use the configuration from the [configuration](configuration) directory in which global and tenant specific settings need to be defined. When the IBM Toolchain with the four pipelines is created, the four github.com/IBM/multi-tenancy* repos are cloned to your GitLab user accounts on the IBM Cloud.

The toolchain can be created simply by invoking this URL: https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/ibm/multi-tenancy-serverless-ci-cd

Note that on the first page the region and the resource group need to be the same ones as defined in [configuration/global.json](configuration/global.json). Leave all other default values.

On the second page you only need to create an API key. Leave all other default values.

After you've created the toolchain, change your configuration in the 'configuration' directory of your GitLab repo. Then you can invoke the first pipeline "pipeline-backend" manually. Once the image has been built, it will trigger the deployment pipelines.

The "pipeline-frontend" pipeline will only work after the backend has been deployed since the frontend containers need to know the endpoints of the backend containers.

## Step by Step Instructions

*Step 1*

Ensure that the two Postgres and AppID service instances have been created.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/002.png" /></kbd>

*Step 2*

Clone or fork the three multi-tenancy* repos:

* https://github.com/IBM/multi-tenancy
* https://github.com/IBM/multi-tenancy-backend
* https://github.com/IBM/multi-tenancy-frontend

*Step 3*

Configure your application in the following three files (replace IBM with your account):

* https://github.com/IBM/multi-tenancy/blob/main/configuration/global.json
* https://github.com/IBM/multi-tenancy/blob/main/configuration/tenants/tenant-a.json
* https://github.com/IBM/multi-tenancy/blob/main/configuration/tenants/tenant-b.json

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/004.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/005.png" /></kbd>

*Step 4*

The toolchain can be created simply by invoking this URL: https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/ibm/multi-tenancy-serverless-ci-cd

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/008.png" /></kbd>

Replace the links to the three repos with your repos. Leave all other defaults on the first page.

*Step 5*

On the second page create an IBM Cloud API key.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/012.png" /></kbd>

*Step 6*

Click 'create' to create the toolchain.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/013.png" /></kbd>

As a result you'll see these repos and pipelines:

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/015.png" /></kbd>

*Step 7*

When triggered, the backend pipeline will execute these tasks:

* Read configuration from JSON files
* Build the backend image and push it to the IBM container registry
* For each tenant invoke the pipeline-backend-tenant pipeline

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/017.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/018.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/019.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/021.png" /></kbd>

*Step 8*

For each tenant containers are deployed to Code Engine:

* Read tenant specific configuration
* Deploy to Code Engine

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/022.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/023.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/025.png" /></kbd>

*Step 9*

The backend containers have been deployed to Code Engine.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/026.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/027.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/028.png" /></kbd>

*Step 10*

The (unprotected) backend endpoint can now be invoked via '.../category/2/products'.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/029.png" /></kbd>

*Step 11*

After the backend has been deployed, the frontend can be deployed. The frontend needs to know the endpoint of the backend. 

Repeat the steps above to build the frontend image.

*Step 12*

After the frontend image has been built, the containers are deployed for different tenants.

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/033.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/034.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/035.png" /></kbd>

*Step 13*

Once deployed, the frontend can be launched.

User: thomas@example.com, password: thomas4appid

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/031.png" /></kbd>

<kbd><img src="https://raw.githubusercontent.com/IBM/multi-tenancy-documentation/main/documentation/images/cicd-serverless/032.png" /></kbd>