/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	b64 "encoding/base64"
	"encoding/json"
	"time"

	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	saasv1alpha1 "github.com/multi-tenancy/operator/api/v1alpha1"
	"github.com/multi-tenancy/operator/helpers"
	"github.com/multi-tenancy/operator/postgresHelper"

	// imports to apply to the reconsile loop
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	ibmAppId "github.com/multi-tenancy/operator/appIdHelper"

	netv1 "k8s.io/api/networking/v1"
)

// turn on and of custom debugging output
var customLogger bool = true

// ECommerceApplicationReconciler reconciles a ECommerceApplication object
type ECommerceApplicationReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// Used to deserialize connection strings for IBM Cloud services
type PostgresBindingJSON struct {
	Cli      Cli      `json:"cli"`
	Postgres Postgres `json:"postgres"`
}

type Cli struct {
	Arguments   []Argument  `json:"argument"`
	Bin         string      `json:"bin"`
	Certificate Certificate `json:"certificate"`
	Composed    []string    `json:"composed"`
	Environment Environment `json:"environment"`
	Type        string      `json:"type"`
}

type Argument struct {
	arr []string
}

type Certificate struct {
	CertificateAuthority string `json:"certificate_authority"`
	CertificateBase64    string `json:"certificate_base64"`
	Name                 string `json:"name"`
}

type Environment struct {
	PgpPassword   string `json:"PGPASSWORD"`
	PgSslRootCert string `json:"PGSSLROOTCERT"`
}

type Postgres struct {
	Authentication Authentication `json:"authentication"`
	Certificate    Certificate    `json:"certificate"`
	Composed       []string       `json:"composed"`
	Database       string         `json:"database"`
	Hosts          []Hosts        `json:"hosts"`
	Path           string         `json:"path"`
	QueryOptions   QueryOptions   `json:"query_options"`
	Scheme         string         `json:"scheme"`
	Type           string         `json:"type"`
}

type Authentication struct {
	Method   string `json:"method"`
	Password string `json:"password"`
	Username string `json:"username"`
}

type Hosts struct {
	Hostname string `json:"hostname"`
	Port     int    `json:"port"`
}

type QueryOptions struct {
	SslMode string `json:"sslmode"`
}

var data PostgresBindingJSON
var postgresTableExists bool = false

//+kubebuilder:rbac:groups=saas.saas.ecommerce.sample.com,resources=ecommerceapplications,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=saas.saas.ecommerce.sample.com,resources=ecommerceapplications/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=saas.saas.ecommerce.sample.com,resources=ecommerceapplications/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;watch

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the ECommerceApplication object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.11.0/pkg/reconcile
func (r *ECommerceApplicationReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)
	postgresUrl := ""
	// "Verify if a CRD of ECommerceApplication exists"
	logger.Info("Verify if a CRD of ECommerceApplication exists")
	ecommerceapplication := &saasv1alpha1.ECommerceApplication{}
	err := r.Get(ctx, req.NamespacedName, ecommerceapplication)
	var apiKey string
	var managementUrl string
	var clientId string

	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			logger.Info("ECommerceApplication resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		// Error reading the object - requeue the request.
		logger.Error(err, "Failed to get ECommerceApplication")
		return ctrl.Result{}, err
	}

	//*****************************************
	// Create Secrets for Frontend and Backend
	//*****************************************
	logger.Info("About to create secret resources")

	// Check if the Postgres Binding secret created by IBM Cloud Operator (ICO) already exists
	secret := &corev1.Secret{}
	err = r.Get(ctx, types.NamespacedName{Name: ecommerceapplication.Spec.PostgresSecretName, Namespace: ecommerceapplication.Namespace}, secret)
	if err != nil && errors.IsNotFound(err) {
		logger.Info("IBM Cloud Binding secret for Postgres does not exist, wait for a while")
		return ctrl.Result{RequeueAfter: time.Second * 300}, nil
	} else if err == nil {
		// ICO Postgres Secret exists
		// Try to unmarshal the contents of the ICO Binding secret
		if err := json.Unmarshal(secret.Data["connection"], &data); err != nil {
			log.Log.Error(err, "could not unmarshal data")
			return ctrl.Result{}, err
		}

		// Create secrets for backend connection to Postgres
		// Create secret postgres.username
		targetSecretName := "postgres.username"
		targetSecret, err := defineSecret(targetSecretName, ecommerceapplication.Namespace, "POSTGRES_USERNAME", data.Postgres.Authentication.Username)
		// Error defining the secret - requeue the request.
		if err != nil {
			return ctrl.Result{}, err
		}
		err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
		secretErr := verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
		if secretErr != nil && errors.IsNotFound(secretErr) {
			return ctrl.Result{}, secretErr
		}

		// Create secret postgres.password
		targetSecretName = "postgres.password"
		targetSecret, err = defineSecret(targetSecretName, ecommerceapplication.Namespace, "POSTGRES_PASSWORD", data.Postgres.Authentication.Password)
		// Error defining the secret - requeue the request.
		if err != nil {
			return ctrl.Result{}, err
		}
		err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
		secretErr = verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
		if secretErr != nil && errors.IsNotFound(secretErr) {
			return ctrl.Result{}, secretErr
		}

		// Create secret postgres.certificate-data
		targetSecretName = "postgres.certificate-data"
		decodeArr, _ := b64.StdEncoding.DecodeString(data.Postgres.Certificate.CertificateBase64)
		certDecoded := string(decodeArr[:])
		targetSecret, err = defineSecret(targetSecretName, ecommerceapplication.Namespace, "POSTGRES_CERTIFICATE_DATA", certDecoded)
		// Error defining the secret - requeue the request.
		if err != nil {
			return ctrl.Result{}, err
		}
		err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
		secretErr = verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
		if secretErr != nil && errors.IsNotFound(secretErr) {
			return ctrl.Result{}, secretErr
		}

		// Create secret postgres.url
		targetSecretName = "postgres.url"
		postgresUrl = fmt.Sprintf("%s%s%s%d%s%s%s", "jdbc:postgresql://", data.Postgres.Hosts[0].Hostname, ":", data.Postgres.Hosts[0].Port, "/", data.Postgres.Database, "?sslmode=verify-full&sslrootcert=/cloud-postgres-cert")
		targetSecret, err = defineSecret(targetSecretName, ecommerceapplication.Namespace, "POSTGRES_URL", postgresUrl)
		// Error defining the secret - requeue the request.
		if err != nil {
			return ctrl.Result{}, err
		}
		err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
		secretErr = verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
		if secretErr != nil && errors.IsNotFound(secretErr) {
			return ctrl.Result{}, secretErr
		}
	}

	// Check if the App Id Binding secret created by IBM Cloud Operator already exists
	err = r.Get(ctx, types.NamespacedName{Name: ecommerceapplication.Spec.AppIdSecretName, Namespace: ecommerceapplication.Namespace}, secret)
	if err != nil && errors.IsNotFound(err) {
		logger.Info("App Id Binding Secret does not exist, wait for a while")
		return ctrl.Result{RequeueAfter: time.Second * 300}, nil
	} else if err == nil {
		//ICO App Id secret exists
		managementUrl = string(secret.Data["managementUrl"])
		tenantId := secret.Data["tenantId"]
		logger.Info(fmt.Sprintf("App Id managementUrl = %s", managementUrl))
		logger.Info(fmt.Sprintf("App Id tenantId = %s", tenantId))

		// Create secret appid.oauthserverurl
		targetSecretName := "appid.oauthserverurl"
		authServerUrl := string(secret.Data["oauthServerUrl"])
		targetSecret, err := defineSecret(targetSecretName, ecommerceapplication.Namespace, "APPID_AUTH_SERVER_URL", authServerUrl)
		logger.Info(fmt.Sprintf("App Id AuthServerUrl = %s", authServerUrl))
		logger.Info("Creating appid.oauthserverurl")
		// Error creating replicating the secret - requeue the request.
		err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
		secretErr := verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
		if secretErr != nil && errors.IsNotFound(secretErr) {
			return ctrl.Result{}, secretErr
		}

		// Create secret appid.client-id-catalog-service
		targetSecretName = "appid.client-id-catalog-service"
		// Use AppIdHelper package to retrieve the client Id of the App Id 'Application', via REST API to IBM Cloud.  If no App Id Applications exist, it must be created and configured by the AppIdHelper.
		apiKey, err = getIbmCloudApiKey(r, ecommerceapplication.Spec.IbmCloudOperatorSecretName, ecommerceapplication.Spec.IbmCloudOperatorSecretNamespace)
		if err != nil {
			return ctrl.Result{}, err
		}
		clientId, err = ibmAppId.ConfigureAppId(managementUrl, apiKey, string(tenantId), ecommerceapplication.Spec.TenantName, ctx)
		if err != nil {
			// Error retrieving client Id - requeue the request.
			return ctrl.Result{RequeueAfter: time.Minute}, nil
		} else {
			logger.Info(fmt.Sprintf("App Id client Id = %s", clientId))
			// Create new secret for backend using App Id clientId
			targetSecret, err = defineSecret(targetSecretName, ecommerceapplication.Namespace, "APPID_CLIENT_ID", clientId)
			// Error defining the secret - requeue the request.
			if err != nil {
				return ctrl.Result{}, err
			}
			err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
			secretErr := verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
			if secretErr != nil && errors.IsNotFound(secretErr) {
				return ctrl.Result{}, secretErr
			}
		}
	}

	//*****************************************
	// Populate Postgres Database
	//*****************************************

	logger.Info("About to populate database")
	if !postgresTableExists {
		postgresUrl = fmt.Sprintf("%s%s%s%s%s%s%s%d%s%s", "postgresql://", data.Postgres.Authentication.Username, ":", data.Postgres.Authentication.Password, "@", data.Postgres.Hosts[0].Hostname, ":", data.Postgres.Hosts[0].Port, "/", data.Postgres.Database)
		logger.Info("About to create database: " + postgresUrl)
		err, postgresTableExists = postgresHelper.CreateExampleDatabase(postgresUrl, ctx)
		if err != nil {
			logger.Error(err, "Can't create initial tables in database")
			return ctrl.Result{}, err
		} else {
			if postgresTableExists {
				logger.Info("Tables created")
			} else {
				logger.Info("Tables exists")
			}
		}
	}

	//*****************************************
	// Create Backend Deployment
	//*****************************************

	logger.Info("About to create backend deployment")
	// Check if the backend deployment already exists, if not create a new one
	found := &appsv1.Deployment{}
	deploymentName := fmt.Sprintf("%s%s", ecommerceapplication.Name, "-backend")
	err = r.Get(ctx, types.NamespacedName{Name: deploymentName, Namespace: ecommerceapplication.Namespace}, found)
	if err != nil && errors.IsNotFound(err) {
		// Define a new deployment
		dep := r.deploymentForbackend(ecommerceapplication, ctx)
		logger.Info("Creating a new backend Deployment", "Deployment.Namespace", dep.Namespace, "Deployment.Name", dep.Name)
		err = r.Create(ctx, dep)
		if err != nil {
			logger.Error(err, "Failed to create new backend Deployment", "Deployment.Namespace", dep.Namespace, "Deployment.Name", dep.Name)
			return ctrl.Result{}, err
		}
		// Deployment created successfully - return and requeue
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		logger.Error(err, "Failed to get Deployment")
		return ctrl.Result{}, err
	}

	// Create a service using Cluster IP to access backend pod
	helpers.CustomLogs("Create backend Service using Cluster IP", ctx, customLogger)
	targetBackendServ, err := defineBackendServiceClusterIp(ecommerceapplication.Name, ecommerceapplication.Namespace)
	if err != nil {
		// Error creating Service
		return ctrl.Result{}, err
	}
	backendService := &corev1.Service{}
	err = r.Get(context.TODO(), types.NamespacedName{Name: targetBackendServ.Name, Namespace: targetBackendServ.Namespace}, backendService)
	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Target service %s doesn't exist, creating it", targetBackendServ.Name))
		err = r.Create(context.TODO(), targetBackendServ)
		if err != nil {
			return ctrl.Result{}, err
		}
	} else {
		logger.Info(fmt.Sprintf("Target service %s exists, updating it now", targetBackendServ.Name))
		// TODO - this update generates an error
		/*err = r.Update(context.TODO(), targetBackendServ)
		if err != nil {
			logger.Error(err, "could not update backend service")
			return ctrl.Result{}, err
		}*/
	}

	// Create Ingress for backend pod
	ingressName := fmt.Sprintf("%s%s%s", "ingress-", ecommerceapplication.Name, "-backend")
	targetBackendIngress, _, err := defineIngress(ingressName, ecommerceapplication.Namespace, ecommerceapplication.Spec.IngressHostname, targetBackendServ.Name, int(targetBackendServ.Spec.Ports[0].Port), ecommerceapplication.Spec.IngressTlsSecretName)
	if err != nil {
		// Error defining Ingress
		return ctrl.Result{}, err
	}
	backendIngress := &netv1.Ingress{}
	err = r.Get(context.TODO(), types.NamespacedName{Name: targetBackendIngress.Name, Namespace: targetBackendIngress.Namespace}, backendIngress)
	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Target ingress %s doesn't exist, creating it", targetBackendIngress.Name))
		err = r.Create(context.TODO(), targetBackendIngress)
		if err != nil {
			return ctrl.Result{}, err
		}
	} else {
		logger.Info(fmt.Sprintf("Target service %s exists, updating it now", targetBackendIngress.Name))
		// TODO For some reason this fails.  Need to fix this.
		/*err = r.Update(context.TODO(), targetBackendIngress)
		if err != nil {
			return ctrl.Result{}, err
		}*/
	}

	//*****************************************
	// Create Frontend Deployment
	//*****************************************
	logger.Info("About to create frontend resources")
	// Check if the deployment already exists, if not create a new one
	logger.Info("Verify if the deployment already exists, if not create a new one")
	found = &appsv1.Deployment{}
	frontend_deployment := "frontend" + ecommerceapplication.Name
	err = r.Get(ctx, types.NamespacedName{Name: frontend_deployment, Namespace: ecommerceapplication.Namespace}, found)
	if err != nil && errors.IsNotFound(err) {
		// Define a new deployment
		dep := r.deploymentForFrontend(ecommerceapplication, ctx, frontend_deployment)
		logger.Info("Creating a new Deployment", "Deployment.Namespace", dep.Namespace, "Deployment.Name", dep.Name)
		err = r.Create(ctx, dep)
		if err != nil {
			logger.Error(err, "Failed to create new Deployment", "Deployment.Namespace", dep.Namespace, "Deployment.Name", dep.Name)
			return ctrl.Result{}, err
		}
		// Deployment created successfully - return and requeue
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		logger.Error(err, "Failed to get Deployment")
		return ctrl.Result{}, err
	}

	//*****************************************
	// Define service NodePort
	/*
		//Don't need Node Ports if we are going to use Ingress
			servPort := &corev1.Service{}
			helpers.CustomLogs("Define service NodePort", ctx, customLogger)

			//*****************************************
			// Create service NodePort
			helpers.CustomLogs("Create service NodePort", ctx, customLogger)

			targetServPort, err := defineFrontendServiceNodePort(ecommerceapplication.Name, ecommerceapplication.Namespace)

			// Error creating replicating the secret - requeue the request.
			if err != nil {
				return ctrl.Result{}, err
			}

			err = r.Get(context.TODO(), types.NamespacedName{Name: targetServPort.Name, Namespace: targetServPort.Namespace}, servPort)
			if err != nil && errors.IsNotFound(err) {
				logger.Info(fmt.Sprintf("Target service port %s doesn't exist, creating it", targetServPort.Name))
				err = r.Create(context.TODO(), targetServPort)
				if err != nil {
					return ctrl.Result{}, err
				}
			} else {
				logger.Info(fmt.Sprintf("Target service port %s exists, updating it now", targetServPort.Name))
				// TODO - this causes an error, need to fix it
				//err = r.Update(context.TODO(), targetServPort)
				//if err != nil {
					//return ctrl.Result{}, err
				//}
			}*/

	// Define cluster IP service to access frontend pods
	servClust := &corev1.Service{}
	helpers.CustomLogs("Create service Cluster IP", ctx, customLogger)
	targetFrontendServClust, err := defineFrontendServiceClusterIp(ecommerceapplication.Name, ecommerceapplication.Namespace)
	if err != nil {
		return ctrl.Result{}, err
	}
	err = r.Get(context.TODO(), types.NamespacedName{Name: targetFrontendServClust.Name, Namespace: targetFrontendServClust.Namespace}, servClust)
	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Target service cluster %s doesn't exist, creating it", targetFrontendServClust.Name))
		err = r.Create(context.TODO(), targetFrontendServClust)
		if err != nil {
			return ctrl.Result{}, err
		}
	} else {
		logger.Info(fmt.Sprintf("Target service cluster %s exists, updating it now", targetFrontendServClust.Name))
		// TODO For some reason this fails.  Need to fix this.
		/*err = r.Update(context.TODO(), targetFrontendServClust)
		if err != nil {
			return ctrl.Result{}, err
		}*/
	}

	// Create Ingress to access frontend service
	ingressName = fmt.Sprintf("%s%s%s", "ingress-", ecommerceapplication.Name, "-frontend")
	targetFrontendIngress, frontendUri, err := defineIngress(ingressName, ecommerceapplication.Namespace, ecommerceapplication.Spec.IngressHostname, targetFrontendServClust.Name, int(targetFrontendServClust.Spec.Ports[0].Port), ecommerceapplication.Spec.IngressTlsSecretName)
	if err != nil {
		// Error creating Ingress
		return ctrl.Result{}, err
	}
	frontendIngress := &netv1.Ingress{}
	err = r.Get(context.TODO(), types.NamespacedName{Name: targetFrontendIngress.Name, Namespace: targetFrontendIngress.Namespace}, frontendIngress)
	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Target ingress %s doesn't exist, creating it", targetFrontendIngress.Name))
		err = r.Create(context.TODO(), targetFrontendIngress)
		if err != nil {
			return ctrl.Result{}, err
		}
	} else {
		logger.Info(fmt.Sprintf("Target service %s exists, updating it now", targetFrontendIngress.Name))
		// TODO For some reason this fails.  Need to fix this.
		/*err = r.Update(context.TODO(), targetFrontendIngress)
		if err != nil {
			return ctrl.Result{}, err
		}*/
	}

	// Add Ingess URI to AppId Redirect URIs
	err = ibmAppId.AppendRedirectUrl(managementUrl, apiKey, frontendUri, ctx)
	if err != nil {
		// Error adding App Id Redirect URI - requeue the request.
		return ctrl.Result{RequeueAfter: time.Minute}, nil
	}

	// Create secret appid.client-id-frontend
	secret = &corev1.Secret{}
	helpers.CustomLogs("Create secret appid.client-id-frontend", ctx, customLogger)
	targetSecretName := "appid.client-id-frontend"
	//clientId := "b12a05c3-8164-45d9-a1b8-af1dedf8ccc3"
	targetSecret, err := defineSecret(targetSecretName, ecommerceapplication.Namespace, "VUE_APPID_CLIENT_ID", clientId)
	// Error creating replicating the secret - requeue the request.
	if err != nil {
		return ctrl.Result{}, err
	}
	err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
	secretErr := verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
	if secretErr != nil && errors.IsNotFound(secretErr) {
		return ctrl.Result{}, secretErr
	}

	//*****************************************
	// Create secret appid.discovery-endpoint
	targetSecretName = "appid.discovery-endpoint"
	discoveryEndpoint := fmt.Sprintf("%s%s", managementUrl, "/.well-known/openid-configuration")
	//discoveryEndpoint :="https://eu-de.appid.cloud.ibm.com/oauth/v4/3793e3f8-ed31-42c9-9294-bc415fc58ab7/.well-known/openid-configuration"
	targetSecret, err = defineSecret(targetSecretName, ecommerceapplication.Namespace, "VUE_APPID_DISCOVERYENDPOINT", discoveryEndpoint)
	// Error creating replicating the secret - requeue the request.
	if err != nil {
		return ctrl.Result{}, err
	}
	err = r.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
	secretErr = verifySecrectStatus(ctx, r, targetSecretName, targetSecret, err)
	if secretErr != nil && errors.IsNotFound(secretErr) {
		return ctrl.Result{}, secretErr
	}
	return ctrl.Result{}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *ECommerceApplicationReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&saasv1alpha1.ECommerceApplication{}).
		Complete(r)
}

// ********************************************************
// additional functions
// ********************************************************

// ********************************************************
// Kubernetes API specifications

// labelsForTenancyFrontend returns the labels for selecting the resources
// belonging to the given ecommerceapplication CR name.
// Example: Is used in "deploymentForFrontend"
func labelsForFrontend(tenancyfrontendname string, ecommerceapplication_cr string) map[string]string {
	return map[string]string{"app": tenancyfrontendname, "ecommerceapplication_cr": ecommerceapplication_cr}
}

// labelsForTenancyFrontend returns the labels for selecting the resources
// belonging to the given ecommerceapplication CR name.
// Example: Is used in "deploymentForFrontend"
func labelsForBackend(tenancybackendname string, ecommerceapplication_cr string) map[string]string {
	return map[string]string{"app": tenancybackendname, "ecommerceapplication_cr": ecommerceapplication_cr}
}

// deploymentForBackend definition and returns a tenancybackendend Deployment object
func (r *ECommerceApplicationReconciler) deploymentForbackend(m *saasv1alpha1.ECommerceApplication, ctx context.Context) *appsv1.Deployment {

	deploymentName := fmt.Sprintf("%s%s", m.Name, "-backend")

	ls := labelsForBackend(deploymentName, deploymentName)
	replicas := m.Spec.Size

	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      deploymentName,
			Namespace: m.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: ls,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: ls,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{{
						Image: "quay.io/nheidloff/service-catalog:latest",
						Name:  "service-catalog",
						Ports: []corev1.ContainerPort{{
							ContainerPort: 8081,
							Name:          "service-catalog",
						}},
						Env: []corev1.EnvVar{{
							Name: "POSTGRES_USERNAME",
							ValueFrom: &v1.EnvVarSource{
								SecretKeyRef: &v1.SecretKeySelector{
									LocalObjectReference: v1.LocalObjectReference{
										Name: "postgres.username",
									},
									Key: "POSTGRES_USERNAME",
								},
							}},
							{Name: "POSTGRES_CERTIFICATE_DATA",
								ValueFrom: &v1.EnvVarSource{
									SecretKeyRef: &v1.SecretKeySelector{
										LocalObjectReference: v1.LocalObjectReference{
											Name: "postgres.certificate-data",
										},
										Key: "POSTGRES_CERTIFICATE_DATA",
									},
								}},
							{Name: "POSTGRES_PASSWORD",
								ValueFrom: &v1.EnvVarSource{
									SecretKeyRef: &v1.SecretKeySelector{
										LocalObjectReference: v1.LocalObjectReference{
											Name: "postgres.password",
										},
										Key: "POSTGRES_PASSWORD",
									},
								}},
							{Name: "POSTGRES_URL",
								ValueFrom: &v1.EnvVarSource{
									SecretKeyRef: &v1.SecretKeySelector{
										LocalObjectReference: v1.LocalObjectReference{
											Name: "postgres.url",
										},
										Key: "POSTGRES_URL",
									},
								}},
							{Name: "APPID_AUTH_SERVER_URL",
								ValueFrom: &v1.EnvVarSource{
									SecretKeyRef: &v1.SecretKeySelector{
										LocalObjectReference: v1.LocalObjectReference{
											Name: "appid.oauthserverurl",
										},
										Key: "APPID_AUTH_SERVER_URL",
									},
								}},

							{Name: "APPID_CLIENT_ID",
								ValueFrom: &v1.EnvVarSource{
									SecretKeyRef: &v1.SecretKeySelector{
										LocalObjectReference: v1.LocalObjectReference{
											Name: "appid.client-id-catalog-service",
										},
										Key: "APPID_CLIENT_ID",
									},
								}},
						},
						ReadinessProbe: &v1.Probe{
							ProbeHandler: v1.ProbeHandler{
								HTTPGet: &v1.HTTPGetAction{Path: "/q/health/live", Port: intstr.FromInt(8081)},
							},
							InitialDelaySeconds: 20,
						},
						LivenessProbe: &v1.Probe{
							ProbeHandler: v1.ProbeHandler{
								HTTPGet: &v1.HTTPGetAction{Path: "/q/health/ready", Port: intstr.FromInt(8081)},
							},
							InitialDelaySeconds: 40,
						},
					}},
				},
			},
		},
	}

	// Set Memcached instance as the owner and controller
	ctrl.SetControllerReference(m, dep, r.Scheme)
	return dep
}

// deploymentForFrontend definition and returns a tenancyfrontend Deployment object
func (r *ECommerceApplicationReconciler) deploymentForFrontend(frontend *saasv1alpha1.ECommerceApplication, ctx context.Context, frontend_deployment string) *appsv1.Deployment {
	logger := log.FromContext(ctx)
	ls := labelsForFrontend(frontend.Name, frontend.Name)
	replicas := frontend.Spec.Size

	// Just reflect the command in the deployment.yaml
	// for the ReadinessProbe and LivenessProbe
	// command: ["sh", "-c", "curl -s http://localhost:8080"]
	mycommand := make([]string, 3)
	mycommand[0] = "/bin/sh"
	mycommand[1] = "-c"
	mycommand[2] = "curl -s http://localhost:8080"

	// Using the context to log information
	logger.Info("Logging: Creating a new Deployment", "Replicas", replicas)
	message := "Logging: (Name: " + frontend.Name + ") \n"
	logger.Info(message)
	message = "Logging: (Namespace: " + frontend.Namespace + ") \n"
	logger.Info(message)

	for key, value := range ls {
		message = "Logging: (Key: [" + key + "] Value: [" + value + "]) \n"
		logger.Info(message)
	}

	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      frontend_deployment,
			Namespace: frontend.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: ls,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: ls,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{{
						Image: "quay.io/tsuedbroecker/service-frontend:latest",
						Name:  "service-frontend",
						Ports: []corev1.ContainerPort{{
							ContainerPort: 8080,
							Name:          "nginx-port",
						}},
						Env: []corev1.EnvVar{{
							Name: "VUE_APPID_DISCOVERYENDPOINT",
							ValueFrom: &corev1.EnvVarSource{
								SecretKeyRef: &v1.SecretKeySelector{
									LocalObjectReference: corev1.LocalObjectReference{
										Name: "appid.discovery-endpoint",
									},
									Key: "VUE_APPID_DISCOVERYENDPOINT",
								},
							}},
							{Name: "VUE_APPID_CLIENT_ID",
								ValueFrom: &corev1.EnvVarSource{
									SecretKeyRef: &corev1.SecretKeySelector{
										LocalObjectReference: corev1.LocalObjectReference{
											Name: "appid.client-id-frontend",
										},
										Key: "VUE_APPID_CLIENT_ID",
									},
								}},
							{Name: "VUE_APP_API_URL_CATEGORIES",
								Value: "VUE_APP_API_URL_CATEGORIES_VALUE",
							},
							{Name: "VUE_APP_API_URL_PRODUCTS",
								Value: "VUE_APP_API_URL_PRODUCTS_VALUE",
							},
							{Name: "VUE_APP_API_URL_ORDERS",
								Value: "VUE_APP_API_URL_ORDERS_VALUE",
							},
							{Name: "VUE_APP_CATEGORY_NAME",
								Value: "VUE_APP_CATEGORY_NAME_VALUE",
							},
							{Name: "VUE_APP_HEADLINE",
								Value: "VUE_APP_HEADLINE_VALUE",
							},
							{Name: "VUE_APP_ROOT",
								Value: "/",
							}}, // End of Env listed values and Env definition
						ReadinessProbe: &corev1.Probe{
							ProbeHandler: corev1.ProbeHandler{
								Exec: &corev1.ExecAction{Command: mycommand},
							},
							InitialDelaySeconds: 20,
						},
						LivenessProbe: &corev1.Probe{
							ProbeHandler: corev1.ProbeHandler{
								Exec: &corev1.ExecAction{Command: mycommand},
							},
							InitialDelaySeconds: 20,
						},
					}}, // Container
				}, // PodSec
			}, // PodTemplateSpec
		}, // Spec
	} // Deployment

	// Set TenancyFrontend instance as the owner and controller
	ctrl.SetControllerReference(frontend, dep, r.Scheme)
	return dep
}

// Create Secret definition
func defineSecret(name string, namespace string, key string, value string) (*corev1.Secret, error) {
	m := make(map[string]string)
	m[key] = value

	return &corev1.Secret{
		TypeMeta:   metav1.TypeMeta{APIVersion: "v1", Kind: "Secret"},
		ObjectMeta: metav1.ObjectMeta{Name: name, Namespace: namespace},
		Immutable:  new(bool),
		Data:       map[string][]byte{},
		StringData: m,
		Type:       "Opaque",
	}, nil
}

// Create Ingress definition
func defineIngress(ingressName string, namespace string, hostName string, serviceName string, port int, tlsSecretName string) (*netv1.Ingress, string, error) {

	rulesHost := fmt.Sprintf("%s%s%s", ingressName, ".", hostName)

	var ingressRule netv1.IngressRule
	var httpIngressPath netv1.HTTPIngressPath
	var pathType netv1.PathType
	var ingressServiceBackend netv1.IngressServiceBackend
	var objectMeta metav1.ObjectMeta
	//var ingressTLS netv1.IngressTLS

	// Define map for the annotations
	annotations := make(map[string]string)
	key := "route.openshift.io/termination"
	value := "edge"
	annotations[key] = value

	objectMeta = metav1.ObjectMeta{
		Name:                       ingressName,
		GenerateName:               "",
		Namespace:                  namespace,
		SelfLink:                   "",
		UID:                        "",
		ResourceVersion:            "",
		Generation:                 0,
		CreationTimestamp:          metav1.Time{},
		DeletionTimestamp:          &metav1.Time{},
		DeletionGracePeriodSeconds: new(int64),
		Labels:                     map[string]string{},
		Annotations:                annotations,
		OwnerReferences:            []metav1.OwnerReference{},
		Finalizers:                 []string{},
		ClusterName:                "",
		ManagedFields:              []metav1.ManagedFieldsEntry{},
	}

	pathType = netv1.PathTypeImplementationSpecific

	ingressServiceBackend = netv1.IngressServiceBackend{
		Name: serviceName,
		Port: netv1.ServiceBackendPort{
			//Name:   serviceName,
			Number: 80,
		},
	}

	httpIngressPath = netv1.HTTPIngressPath{
		Path:     "/",
		PathType: &pathType,
		Backend: netv1.IngressBackend{
			Service: &ingressServiceBackend,
		},
	}

	ingressRule = netv1.IngressRule{
		Host: rulesHost,
		IngressRuleValue: netv1.IngressRuleValue{
			HTTP: &netv1.HTTPIngressRuleValue{
				Paths: []netv1.HTTPIngressPath{httpIngressPath},
			},
		},
	}

	/*ingressTLS = netv1.IngressTLS{
		Hosts:      []string{rulesHost},
		SecretName: tlsSecretName,
	}*/

	return &netv1.Ingress{
		TypeMeta:   metav1.TypeMeta{APIVersion: "v1", Kind: "Ingress"},
		ObjectMeta: objectMeta,
		Spec: netv1.IngressSpec{
			//IngressClassName: new(string),
			//TLS:   []netv1.IngressTLS{ingressTLS},
			Rules: []netv1.IngressRule{ingressRule},
		},
	}, "http://" + rulesHost, nil

}

// Define Service using NodePort for frontend
/*func defineFrontendServiceNodePort(name string, namespace string) (*corev1.Service, error) {

	serviceLabels := fmt.Sprintf("%s%s", name, "-frontend")
	serviceName := fmt.Sprintf("%s%s%s", "service-", name, "-frontend")

	// Define map for the selector
	mselector := make(map[string]string)
	key := "app"
	value := serviceLabels
	mselector[key] = value

	// Define map for the labels
	mlabel := make(map[string]string)
	key = "app"
	value = "service-frontend"
	mlabel[key] = serviceLabels

	var port int32 = 8080

	return &corev1.Service{
		TypeMeta:   metav1.TypeMeta{APIVersion: "v1", Kind: "Service"},
		ObjectMeta: metav1.ObjectMeta{Name: serviceName, Namespace: namespace, Labels: mlabel},
		Spec: corev1.ServiceSpec{
			Type: corev1.ServiceTypeNodePort,
			Ports: []corev1.ServicePort{{
				Port: port,
				Name: "http",
			}},
			Selector: mselector,
		},
	}, nil
}*/

// Define Service using Cluster IP for backend
func defineBackendServiceClusterIp(name string, namespace string) (*corev1.Service, error) {

	serviceLabels := fmt.Sprintf("%s%s", name, "-backend")
	serviceName := fmt.Sprintf("%s%s%s", "service-", name, "-backend")

	// Define map for the selector
	mselector := make(map[string]string)
	key := "app"
	value := serviceLabels
	mselector[key] = value

	// Define map for the labels
	mlabel := make(map[string]string)
	key = "app"
	value = serviceLabels
	mlabel[key] = value

	var port int32 = 80

	return &corev1.Service{
		TypeMeta:   metav1.TypeMeta{APIVersion: "v1", Kind: "Service"},
		ObjectMeta: metav1.ObjectMeta{Name: serviceName, Namespace: namespace, Labels: mlabel},
		Spec: corev1.ServiceSpec{
			Type: corev1.ServiceTypeClusterIP,
			Ports: []corev1.ServicePort{{
				Port: port,
				Name: "http",
				TargetPort: intstr.IntOrString{
					IntVal: 8081,
				},
			}},
			Selector: mselector,
		},
	}, nil
}

// Create Service ClusterIP definition
func defineFrontendServiceClusterIp(name string, namespace string) (*corev1.Service, error) {

	// Define map for the selector
	mselector := make(map[string]string)
	key := "app"
	value := name
	mselector[key] = value

	// Define map for the labels
	mlabel := make(map[string]string)
	key = "app"
	value = "service-frontend"
	mlabel[key] = value

	var port int32 = 80
	var targetPort int32 = 8080
	var clustserv = name + "clusterip"

	return &corev1.Service{
		TypeMeta:   metav1.TypeMeta{APIVersion: "v1", Kind: "Service"},
		ObjectMeta: metav1.ObjectMeta{Name: clustserv, Namespace: namespace, Labels: mlabel},
		Spec: corev1.ServiceSpec{
			Type: corev1.ServiceTypeClusterIP,
			Ports: []corev1.ServicePort{{
				Port:       port,
				TargetPort: intstr.IntOrString{IntVal: targetPort},
			}},
			Selector: mselector,
		},
	}, nil
}

// ********************************************************
// Helpers to minimize code in reconcile

// Do all the error verification for the vSecrectStatus
func verifySecrectStatus(ctx context.Context, r *ECommerceApplicationReconciler, targetSecretName string, targetSecret *v1.Secret, err error) error {
	logger := log.FromContext(ctx)

	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Target secret %s doesn't exist, creating it", targetSecretName))
		err = r.Create(context.TODO(), targetSecret)
		if err != nil {
			return err
		}
	} else {
		logger.Info(fmt.Sprintf("Target secret %s exists, updating it now", targetSecretName))
		err = r.Update(context.TODO(), targetSecret)
		if err != nil {
			return err
		}
	}

	return err
}

// Retrieve IBM Cloud API key from secret used by IBM Cloud Operator
func getIbmCloudApiKey(r *ECommerceApplicationReconciler, name string, namespace string) (apiKey string, err error) {

	secret := &corev1.Secret{}
	err = r.Get(context.TODO(), types.NamespacedName{Name: name, Namespace: namespace}, secret)
	if err != nil && errors.IsNotFound(err) {
		log.Log.Error(err, "IBM Cloud Operator secret was not found.  Cannot access IBM Cloud API key")
		return "", err

	} else {

		apiKey := secret.Data["api-key"]
		return string(apiKey), nil
	}
}
