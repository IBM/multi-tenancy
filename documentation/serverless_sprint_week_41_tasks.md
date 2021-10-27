# Tasks for sprint in week 41 `serverless`

### Table of tasks

* Project tasks/activities in [ZenHub link](https://github.com/karimdeif/multi-tenancy#workspaces/serverless-6152c725095153001243b1aa/board?repos=388999110)

|   | Objectives |  Status | Priority |  Notes | 
|---|---|---|---|---|
| 1 | **Running simple ecommerce application including Quarkus on Code Engine** |  in progress | high |Running example: [tenant b](https://frontend-oidc-b.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/), [tenant a](https://frontend-oidc-a.ceqctuyxg6m.us-south.codeengine.appdomain.cloud/)  |
| 1.0 | - Create a folder for the source code of the applications called **code** |  **done** | high | Inside the folder the name on the subfolders should refect the appliation name. |
| 1.1 | - AppID setup |  **done** | high |  |
| 1.2 | - AppID integration to frontend |  **done** | high |  |
| 1.3 | - AppID integration to Backend |  open | high |  |
| 1.4 | - Backend database postgres integration |  done | high |  |
| 1.5 | - Deploy to Code Engine |  in progress | high | the intergrated appid frontend and postgress backend is deployed |
| 2 | **Automation of the deployment** | in progress | high |  |
| 2.0 | - Define a folder structure for the **installation/setup and CI/CD** | **done** | high | one folder call **installapp** (first time installation) **cicd** (continuous delivery realization with tekton) |
| 2.1 | - Create containers and save them in a public container registry | open | high |  |
| 2.2 | - Create a bash automation for the creation and configuration of AppID | inprogress | high | Thomas need to copy the work he did the the project. |
| 2.3 | - Create a bash automation for the creation and configuration of postgres | open | high |  |
| 2.4 | - Create a bash automation for deployment to Code Engine | in progress | high |  |
| 2.5 | - Setup tekton using the IBM Cloud toolchain | in progress | high |  |
| 2.6 | - Integrate exiting bash automations to tekton pipeline | open | high |  |
| 2.7 | - Add an admin UI for onboarding of new tenant roberts application |  open | low |  |
| 2.7 | - Problem to start the frontend container in code engine |  open | high |  |
| 3 | **Documenation of the setup** | open | high | We should use **mkdocs** |  
| 3.1 | - Manual setup | open | high |  |  
| 3.2 | - Automation setup | open | high |  |
| 3.3 | - Workshop  | open | low |  |
