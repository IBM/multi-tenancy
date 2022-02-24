# Manage concurrent local operator development

### Step 1: Login to the cluster

### Step 2: Create an `operator development project` for each developer on the cluster

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

### Step 6: Execute the operator locally 

```sh
make install run  
```



