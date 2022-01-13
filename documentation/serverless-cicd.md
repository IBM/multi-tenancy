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
