# Develop Backend Service locally

To run the backend service locally, a [managed Postgres](https://cloud.ibm.com/databases/databases-for-postgresql/create) instance needs to be created first. After this you need to define four variables in local.env. See local.env.template for more:
- POSTGRES_USERNAME
- POSTGRES_PASSWORD
- POSTGRES_URL
- POSTGRES_CERTIFICATE_FILE_NAME

Additionally you need to copy the certificate file in ./src/main/resources/certificates. As file name use the Postgres username.

For the authentication a [App ID](https://www.ibm.com/cloud/app-id) instance is required. Copy the two settings in local.env:
- APPID_CLIENT_ID (note: this is not the client id in the secrets, but in the application settings)
- APPID_DISCOVERYENDPOINT

For IBMers only: You can re-use existing services by using these [configuration](https://github.ibm.com/niklas-heidloff/multi-tenancy-credentials) files.

```
$ git clone https://github.com/IBM/multi-tenancy.git
$ git clone https://github.com/IBM/multi-tenancy-backend.git
$ cd multi-tenancy
$ ROOT_FOLDER=$(pwd)
$ cp certificate ${root_folder}/src/main/resources/certificates/
$ cp template.local.env local.env
$ vi local.env
```

*Backend*

Run the backend service locally via Maven:

```
$ sh ./scripts/run-locally-backend.sh
```

Or run the backend service locally via container (podman):

```
$ sh ./scripts/run-locally-container-backend.sh
```

Invoke http://localhost:8081/category/2/products

*Frontend*

Run the frontend service locally:

```
$ sh ./scripts/run-locally-frontend.sh
```

Or run the frontend service locally via container (podman):

```
$ sh ./scripts/run-locally-container-frontend.sh
```

Invoke http://localhost:8080

User: thomas@example.com. Password: thomas4appid
