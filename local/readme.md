# Run the example application locally

## Verify that the local configuration

* `multi-tenancy/code/service-catalog/application.properties`
    * Points to an existing postgres database on IBM Cloud
    * TBD -> Points to an existing app id instance on IBM Cloud

* `multi-tenancy/code/frontend/public/env-config.js`
    * Points to an existing app id instance on IBM Cloud
    * Points to the local running `service-catalog` microservice.

## Configure and run the example application locally

* Configure the `path` in following bash scipts:

```sh
start_serice-catalog_A.sh
start_vue-tenant_A.sh
```

* Set the `path` to the downloaded project `multi-tenancy`:

```sh
export HOME_PATH_NEW=$(pwd)
export PATH_TO_CODE="Downloads/dev/multi-tenancy"
```

* Run following bash script from the folder `local`:

```sh
cd [project]/local
bash start-local-application.sh
```
