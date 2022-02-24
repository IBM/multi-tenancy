package appIdHelper

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	ctrllog "sigs.k8s.io/controller-runtime/pkg/log"
)

type appIdApplication struct {
	ClientId       string `json:"clientId"`
	TenantId       string `json:"tenantId"`
	Secret         string `json:"secret"`
	Name           string `json:"name"`
	OAuthServerUrl string `json:"oAuthServerUrl"`
	Type           string `json:"type"`
}

type appIdApplications struct {
	Applications []appIdApplication `json:"applications"`
}

func getAppIdApplications(managementUrl string, ibmCloudApiKey string, tenantId string, ctx context.Context) ([]byte, error) {

	//$ curl -X POST     "https://iam.cloud.ibm.com/identity/token"     -H "content-type: application/x-www-form-urlencoded"     -H "accept: application/json"     -d 'grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=<API_KEY>' > token.json

	/*APPID_MANAGEMENT_URL_ALL_APPLICATIONS=${APPID_MANAGEMENT_URL}/applications
	echo $APPID_MANAGEMENT_URL_ALL_APPLICATIONS
	result=$(curl -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $APPID_MANAGEMENT_URL_ALL_APPLICATIONS)
	echo $result
	APPID_CLIENT_ID=$(echo $result | sed -n 's|.*"clientId":"\([^"]*\)".*|\1|p')
	echo $APPID_CLIENT_ID*/

	log := ctrllog.FromContext(ctx)

	var body []byte

	//clientId := ""
	oauth, err := getIbmCloudOauthToken(ibmCloudApiKey, ctx)
	if err != nil {
		log.Error(err, "Error retrieving IBM Cloud Oauth token")
		return body, err
	}

	url := fmt.Sprintf("%s%s", managementUrl, "/applications")

	client := &http.Client{}

	//appIdUrl := fmt.Sprintf("%s%s", managementUrl, "applications")
	//log.Info(fmt.Sprintf("%s%s", "appIdUrl=", appIdUrl))

	jsonPayload := []byte(fmt.Sprintf("%s%s%s%s", "{\"tenantId\":", "\"", tenantId, "\"}"))
	//jsonPayload := []byte(`{"tenantId":"e38a8715-b8a4-4f1f-82b2-5e434e198768"}`)

	log.Info(fmt.Sprintf("%s%s", "managementUrl=", managementUrl))
	//log.Info(fmt.Sprintf("%s%s", "jsonPayload=", jsonPayload))

	bearer := fmt.Sprintf("%s%s", "Bearer ", oauth)
	log.Info(fmt.Sprintf("%s%s", "bearer=", bearer))

	//jsonStr = []byte(jsonPayload)
	req, err := http.NewRequest("GET", url, bytes.NewBuffer(jsonPayload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", bearer)

	resp, err := client.Do(req)
	if err != nil {
		log.Error(err, "Create GET request failed")
		return body, err
	}
	defer resp.Body.Close()

	log.Info(fmt.Sprintf("%s%s", "response Status:", resp.Status))
	log.Info(fmt.Sprintf("%s%s", "response Headers:", resp.Header))
	//fmt.Println("response Status:", resp.Status)
	//fmt.Println("response Headers:", resp.Header)
	body, _ = ioutil.ReadAll(resp.Body)
	//fmt.Println("response Body:", string(body))

	log.Info(fmt.Sprintf("%s%s", "returning body=", string(body)))
	return body, nil

}

func ConfigureAppId(managementUrl string, ibmCloudApiKey string, tenantId string, tenantName string, ctx context.Context) (string, error) {

	//{"applications":[]}

	var jsonData appIdApplications
	log := ctrllog.FromContext(ctx)
	var clientId string
	//var body []byte

	//Temp
	if true {
		return clientId, nil
	}

	appIdApps, err := getAppIdApplications(managementUrl, ibmCloudApiKey, tenantId, ctx)
	// Error retrieving client Id - requeue the request.
	if err != nil {
		return "", err
	} else {
		// Verify if App Id has applications configured
		err = json.Unmarshal(appIdApps, &jsonData)
		if err != nil {
			log.Error(err, "unmarshall error")
			return "", err
		}

		if len(jsonData.Applications) == 0 {
			log.Info("App Id Application count is 0.  Need to perform initial App Id configuration")

			// Add Application
			clientId, err := addApplication(managementUrl, ibmCloudApiKey, tenantName, ctx)
			if err != nil {
				return "", err
			}
			log.Info(fmt.Sprintf("%s%s", "addApplication clientId=", clientId))

			// Add Scope
			err = addScope(managementUrl, ibmCloudApiKey, clientId, ctx)
			if err != nil {
				return "", err
			}
			//addRole()
			//addUsers()
			//configureUiText()
			//configureUiColour()
			//configureUiImage()

			//jsonData.Applications[0].ClientId

		} else {
			log.Info("App Id Application count is more than zero.  Return the clientId for the first application")
		}

	}

	return clientId, nil

}

func addApplication(managementUrl string, ibmCloudApiKey string, tenantName string, ctx context.Context) (string, error) {

	/*
			sed "s+FRONTENDNAME+$FRONTEND_NAME+g" ./appid-configs/add-application-template.json > ./$ADD_APPLICATION
		    result=$(curl -d @./$ADD_APPLICATION -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/applications)
	*/

	/*{
		"name": "FRONTENDNAME",
		"type": "singlepageapp"
	}*/

	var clientId string
	url := fmt.Sprintf("%s%s", managementUrl, "/applications/")
	jsonPayload := []byte(fmt.Sprintf("%s%s%s%s%s%s", "{\"name\":", "\"", tenantName, "\"", ",", "\"type\": \"singlepageapp\"}"))
	body, err := doHttpPost(jsonPayload, url, ibmCloudApiKey, ctx)
	var jsonData appIdApplication

	if err != nil {
		return clientId, err
	}

	err = json.Unmarshal(body, &jsonData)
	if err != nil {
		return clientId, err
	}

	clientId = jsonData.ClientId

	return clientId, nil
}

func addScope(managementUrl string, ibmCloudApiKey string, clientId string, ctx context.Context) error {

	/*
		OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
			result=$(curl -d @./$ADD_SCOPE -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/applications/$APPLICATION_CLIENTID/scopes)
	*/

	url := fmt.Sprintf("%s%s%s%s", managementUrl, "/applications/", clientId, "/scopes")
	jsonPayload := []byte("{\"scopes\": [\"tenant_scope\"]}")
	_, err := doHttpPost(jsonPayload, url, ibmCloudApiKey, ctx)

	if err != nil {
		return err
	}
	return nil
}

func addRole(managementUrl string, ibmCloudApiKey string, tenantId string, ctx context.Context) error {
	/*
			sed "s+APPLICATIONID+$APPLICATION_CLIENTID+g" ./appid-configs/add-roles-template.json > ./$ADD_ROLE
		    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
		    #echo $OAUTHTOKEN
		    result=$(curl -d @./$ADD_ROLE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/roles)
	*/
	return nil
}

func addUsers(managementUrl string, ibmCloudApiKey string, tenantId string, ctx context.Context) error {
	/*
			OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
		    result=$(curl -d @./$USER_IMPORT_FILE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/cloud_directory/import?encryption_secret=$ENCRYPTION_SECRET)
	*/
	return nil
}

func configureUiText(managementUrl string, ibmCloudApiKey string, tenantId string, ctx context.Context) error {
	/*
	   	sed "s+FRONTENDNAME+$FRONTEND_NAME+g" ./appid-configs/add-ui-text-template.json > ./$ADD_UI_TEXT
	       OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
	       echo "PUT url: $MANAGEMENTURL/config/ui/theme_txt"
	       result=$(curl -d @./$ADD_UI_TEXT -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_text)
	*/
	return nil
}

func configureUiColour(managementUrl string, ibmCloudApiKey string, tenantId string, ctx context.Context) error {
	/*
		OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
			echo "PUT url: $MANAGEMENTURL/config/ui/theme_color"
			result=$(curl -d @./$ADD_COLOR -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_color)
	*/
	return nil
}

func configureUiImage(managementUrl string, ibmCloudApiKey string, tenantId string, ctx context.Context) error {
	/*
	   	OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
	       echo "POST url: $MANAGEMENTURL/config/ui/media?mediaType=logo"
	       result=$(curl -F "file=@./$ADD_IMAGE" -H "Content-Type: multipart/form-data" -X POST -v -H "Authorization: Bearer $OAUTHTOKEN" "$MANAGEMENTURL/config/ui/media?mediaType=logo")
	*/
	return nil
}

func doHttpPost(jsonPayload []byte, url string, ibmCloudApiKey string, ctx context.Context) ([]byte, error) {

	log := ctrllog.FromContext(ctx)
	var body []byte
	client := &http.Client{}

	log.Info(fmt.Sprintf("%s%s", "url=", url))
	log.Info(fmt.Sprintf("%s%s", "jsonPayload=", string(jsonPayload)))

	oauth, err := getIbmCloudOauthToken(ibmCloudApiKey, ctx)
	if err != nil {
		log.Error(err, "Error retrieving IBM Cloud Oauth token")
		return body, err
	}

	bearer := fmt.Sprintf("%s%s", "Bearer ", oauth)

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonPayload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", bearer)

	resp, err := client.Do(req)
	if err != nil {
		log.Error(err, "Create POST request failed")
		return body, err
	}
	defer resp.Body.Close()

	log.Info(fmt.Sprintf("%s%s", "response Status:", resp.Status))
	log.Info(fmt.Sprintf("%s%s", "response Headers:", resp.Header))

	body, _ = ioutil.ReadAll(resp.Body)

	log.Info(fmt.Sprintf("%s%s", "returning body=", string(body)))
	return body, nil

}

func getIbmCloudOauthToken(apiKey string, ctx context.Context) (string, error) {

	type oauthBindingJSON struct {
		Access_token  string `json:"access_token"`
		Refresh_token string `json:"refresh_token"`
		Ims_user_id   int    `json:"ims_user_id"`
		Token_type    string `json:"token_type"`
		Expires_in    int    `json:"expires_in"`
		Expiration    int    `json:"expiration"`
		Scope         string `json:"scope"`
	}

	log := ctrllog.FromContext(ctx)

	endpoint := "https://iam.cloud.ibm.com/identity/token"
	data := url.Values{}
	data.Set("grant_type", "urn:ibm:params:oauth:grant-type:apikey")

	data.Set("apikey", apiKey)

	client := &http.Client{}

	r, err := http.NewRequest("POST", endpoint, strings.NewReader(data.Encode())) // URL-encoded payload
	if err != nil {
		log.Error(err, "Create request failed")
		return "", err
	}
	r.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Add("Content-Length", strconv.Itoa(len(data.Encode())))

	res, err := client.Do(r)
	if err != nil {
		log.Error(err, "Post failed")
		return "", err
	}
	log.Info(res.Status)
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Error(err, "Reading response failed")
		return "", err
	}

	log.Info(string(body))

	var jsonData oauthBindingJSON

	err = json.Unmarshal(body, &jsonData)
	if err != nil {
		log.Error(err, "unmarshall error")
		return "", err
	}

	return jsonData.Access_token, nil
}
