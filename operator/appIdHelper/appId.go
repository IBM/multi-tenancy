package appIdHelper

import (
	corev1 "k8s.io/api/core/v1"
)

func GetClientId(secret corev1.Secret) (string, error) {

	//APPID_MANAGEMENT_URL
	//OAUTHTOKEN

	var clientId = ""

	// Retrieve the App Id secret

	clientId = "b12a05c3-8164-45d9-a1b8-af1dedf8ccc3"
	//managementUrl := secret.Data["managementUrl"]

	return clientId, nil
}
