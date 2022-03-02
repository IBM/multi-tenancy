

```sh
cd multi-tenancy
```

Open the `globle.json`

```sh
nano ./configuration/global.json
```

Replace the value for the namespace one of your choose:
`"NAMESPACE":"multi-tenancy-example` to `"NAMESPACE":"YOUR_VALUE"`.

```json
{
  "IBM_CLOUD": {
    "RESOURCE_GROUP": "default",
    "REGION": "eu-de"
  },
  "REGISTRY": {
    "URL": "de.icr.io",
    "NAMESPACE": "multi-tenancy-example", <- INSERT YOUR VALUE
    "TAG": "v2",
    "SECRET_NAME": "multi.tenancy.cr.sec"
  },
  "IMAGES": {
    "NAME_BACKEND": "multi-tenancy-service-backend",
    "NAME_FRONTEND": "multi-tenancy-service-frontend"
  }
}
```

Open the first tenant configuration `tenant-a.json`

```sh
nano ./configuration/tenants/tenant-a.json
```

Replace the value for the project name of the Code Engine project to one of your choose:
`"PROJECT_NAME":"multi-tenancy-serverless-a` to `"PROJECT_NAME":"YOUR_VALUE"`.

```json
{
  "APP_ID": {
    "SERVICE_INSTANCE": "multi-tenancy-serverless-appid-a",
    "SERVICE_KEY_NAME": "multi-tenancy-serverless-appid-key-a"
  },
  "POSTGRES": {
    "SERVICE_INSTANCE": "multi-tenancy-serverless-pg-ten-a",
    "SERVICE_KEY_NAME": "multi-tenancy-serverless-pg-ten-a-key",
    "SQL_FILE": "create-populate-tenant-a.sql"
  },
  "APPLICATION": {
    "CONTAINER_NAME_BACKEND": "multi-tenancy-service-backend-movies",
    "CONTAINER_NAME_FRONTEND": "multi-tenancy-service-frontend-movies",
    "CATEGORY": "Movies"
  },
  "CODE_ENGINE": {
    "PROJECT_NAME": "multi-tenancy-serverless-a-t" <- INSERT YOUR VALUE
  },
  "IBM_KUBERNETES_SERVICE": {
    "NAME": "niklas-heidloff3-fra04-b3c.4x16",
    "NAMESPACE": "tenant-a"
  },
  "IBM_OPENSHIFT_SERVICE": {
    "NAME": "roks-gen2-suedbro",
    "NAMESPACE": "tenant-a"
  },
  "PLATFORM": {
    "NAME": "IBM_OPENSHIFT_SERVICE"
  }
}
```

```sh
cd $ROOT_FOLDER/installapp
```

```sh
ibmcloud login --sso
```

```sh
bash ./ce-create-two-tenancies.sh
```


