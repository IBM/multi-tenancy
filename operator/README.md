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

### Reuse of existing IBM Cloud services

1. Does a developer project already exist and there are instances for AppID and Postgres?

export CLUSTERNAME=roks-gen2-suedbro ibmcloud login --sso

### Step 6: Execute the operator locally 

```sh
make install run  
```

### Known issues:

### IBM Cloud Operator

> Don't delete CRDs for the IBM Cloud Operator and don't delete projects that contains CRDs of the IBM Cloud Operator! The deletion will break the IBM Cloud Operator and you need to install it again. [Related GitHub issue](https://github.com/IBM/cloud-operators/issues/265)



