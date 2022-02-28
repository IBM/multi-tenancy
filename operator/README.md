# Manage concurrent local operator development

### Step 1: Login to the cluster

### Step 2: Create an `operator development project` for you as a developer on the cluster

### Step 3: Navigate to the `operator source code folder`

### Step 4: Ensure you are in your `operator development project` of the cluster

### Step 5: Update the scope of the operator in the `main.go` to your needs

```go
// TODO edit this namespace/project list to support concorrent development when running operator locally with "make install run"
// this changes the operator scope from cluster to namespace
// the default namespace must also be included
// var developerNamespaces = []string{"deleeuw", "default"} // List of Namespaces
var developerNamespaces = []string{"saas-operator-development-thomas", "default"} // List of Namespaces
```

# Reuse of existing IBM Cloud services


#### Step 1: Does a developer project already exist with  instances for AppID and Postgres?

```sh
export DEVELOPER_1_PROJECT=""
export DEVELOPER_2_PROJECT=""
export CLUSTERNAME=roks-gen2-suedbro ibmcloud login --sso
```

### Step 2: Run the copy-and-past-secrets.sh

```sh
sh copy-and-past-secrets.sh
```

### Step 3: When you now create a saas CRD object `saas_v1alpha1_developer2-ecommerceapplication.yaml` and remove all IBM Cloud operator related kinds in the `yaml`

```yaml
apiVersion: saas.saas.ecommerce.sample.com/v1alpha1
kind: ECommerceApplication
metadata:
  name: ecommerceapplication-ten-dev-2
spec:
  size: 1
  appIdSecretName: multi-tenancy-appid-ten-f-secret
  postgresSecretName: multi-tenancy-pg-ten-f-secret
  tenantName: ten-f
  ibmCloudOperatorSecretName: ibmcloud-operator-secret
  ibmCloudOperatorSecretNamespace: default
# The service deleted to ensure developer two will access only the serice bindings
```
### Step 4: Execute the operator locally 

```sh
make install run  
```

### Known issues:

### IBM Cloud Operator

> Don't delete CRDs for the IBM Cloud Operator and don't delete projects that contains CRDs of the IBM Cloud Operator! The deletion will break the IBM Cloud Operator and you need to install it again. [Related GitHub issue](https://github.com/IBM/cloud-operators/issues/265)



