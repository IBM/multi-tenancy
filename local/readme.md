# Run the example local


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