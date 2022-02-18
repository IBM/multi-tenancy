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

	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	saasv1alpha1 "github.com/multi-tenancy/operator/api/v1alpha1"
	"github.com/multi-tenancy/operator/helpers"

	// imports to apply to the reconsile loop
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// turn on and of custom debugging output
var customLogger bool = true

// ECommerceApplicationReconciler reconciles a ECommerceApplication object
type ECommerceApplicationReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

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

	// "Verify if a CRD of ECommerceApplication exists"
	logger.Info("Verify if a CRD of ECommerceApplication exists")
	ecommerceapplication := &saasv1alpha1.ECommerceApplication{}
	err := r.Get(ctx, req.NamespacedName, ecommerceapplication)

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

	// Check if the deployment already exists, if not create a new one
	logger.Info("Verify if the deployment already exists, if not create a new one")

	found := &appsv1.Deployment{}
	err = r.Get(ctx, types.NamespacedName{Name: ecommerceapplication.Name, Namespace: ecommerceapplication.Namespace}, found)

	if err != nil && errors.IsNotFound(err) {
		// Define a new deployment
		dep := r.deploymentForFrontend(ecommerceapplication, ctx)
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
	servPort := &corev1.Service{}
	helpers.CustomLogs("Define service NodePort", ctx, customLogger)

	//*****************************************
	// Create service NodePort
	helpers.CustomLogs("Create service NodePort", ctx, customLogger)

	targetServPort, err := defineServiceNodePort("service-frontend", ecommerceapplication.Namespace)

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
		logger.Info(fmt.Sprintf("Target service port %s exists, updating it now", targetServPort))
		err = r.Update(context.TODO(), targetServPort)
		if err != nil {
			return ctrl.Result{}, err
		}
	}

	//*****************************************
	// Define cluster
	servClust := &corev1.Service{}

	//*****************************************
	// Create service cluster
	helpers.CustomLogs("Create service Cluster IP", ctx, customLogger)

	targetServClust, err := defineServiceClust("service-frontend-cip", ecommerceapplication.Namespace)

	// Error creating replicating the service cluster - requeue the request.
	if err != nil {
		return ctrl.Result{}, err
	}

	err = r.Get(context.TODO(), types.NamespacedName{Name: targetServClust.Name, Namespace: targetServClust.Namespace}, servClust)

	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Target service cluster %s doesn't exist, creating it", targetServClust.Name))
		err = r.Create(context.TODO(), targetServClust)
		if err != nil {
			return ctrl.Result{}, err
		}
	} else {
		logger.Info(fmt.Sprintf("Target service cluster %s exists, updating it now", targetServClust))
		err = r.Update(context.TODO(), targetServClust)
		if err != nil {
			return ctrl.Result{}, err
		}
	}

	//*****************************************
	// Define secret
	helpers.CustomLogs("Define secret", ctx, customLogger)
	secret := &corev1.Secret{}

	//*****************************************
	// Create secret appid.client-id-frontend
	helpers.CustomLogs("Create secret appid.client-id-frontend", ctx, customLogger)

	targetSecretName := "appid.client-id-frontend"
	clientId := "b12a05c3-8164-45d9-a1b8-af1dedf8ccc3"
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
	discoveryEndpoint := "https://eu-de.appid.cloud.ibm.com/oauth/v4/3793e3f8-ed31-42c9-9294-bc415fc58ab7/.well-known/openid-configuration"
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

	logger.Info("Just return nil")
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
func labelsForFrontend(name string) map[string]string {
	return map[string]string{"app": "labelsForTenancyFrontend", "ecommerceapplication_cr": name}
}

// deploymentForTenancyFronted returns a tenancyfrontend Deployment object
func (r *ECommerceApplicationReconciler) deploymentForFrontend(m *v1alpha1.TenancyFrontend, ctx context.Context) *appsv1.Deployment {
	logger := log.FromContext(ctx)
	ls := labelsForFrontend(m.Name)
	replicas := m.Spec.Size

	// Just reflect the command in the deployment.yaml
	// for the ReadinessProbe and LivenessProbe
	// command: ["sh", "-c", "curl -s http://localhost:8080"]
	mycommand := make([]string, 3)
	mycommand[0] = "/bin/sh"
	mycommand[1] = "-c"
	mycommand[2] = "curl -s http://localhost:8080"

	// Using the context to log information
	logger.Info("Logging: Creating a new Deployment", "Replicas", replicas)
	message := "Logging: (Name: " + m.Name + ") \n"
	logger.Info(message)
	message = "Logging: (Namespace: " + m.Namespace + ") \n"
	logger.Info(message)

	for key, value := range ls {
		message = "Logging: (Key: [" + key + "] Value: [" + value + "]) \n"
		logger.Info(message)
	}

	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      m.Name,
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
	ctrl.SetControllerReference(m, dep, r.Scheme)
	return dep
}
