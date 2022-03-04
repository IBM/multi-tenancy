package appIdHelper

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"path/filepath"
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
	/*if true {
		return clientId, nil
	}*/

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
			// Add Role
			err = addRole(managementUrl, ibmCloudApiKey, clientId, ctx)
			if err != nil {
				return "", err
			}

			// Add Users
			err = addUsers(managementUrl, ibmCloudApiKey, ctx)
			if err != nil {
				return "", err
			}

			// Configure UI Text
			err = configureUiText(managementUrl, ibmCloudApiKey, tenantName, ctx)
			if err != nil {
				return "", err
			}

			// Configure UI Colour
			err = configureUiColour(managementUrl, ibmCloudApiKey, ctx)
			if err != nil {
				return "", err
			}

			// Configure UI Image
			// The function below does not yet work.  However, the UI Image is optional.
			/*err = configureUiImage(managementUrl, ibmCloudApiKey, ctx)
			if err != nil {
				return "", err
			}*/

		} else {
			log.Info("App Id Application count is more than zero.  Return the clientId for the first application")
			clientId = jsonData.Applications[0].ClientId
			// Assume for now that this AppId instance is used for only one tenant / application, hence return first clientID
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
	_, err := doHttpPut(jsonPayload, url, ibmCloudApiKey, ctx)

	if err != nil {
		return err
	}
	return nil
}

func addRole(managementUrl string, ibmCloudApiKey string, clientId string, ctx context.Context) error {
	/*
			sed "s+APPLICATIONID+$APPLICATION_CLIENTID+g" ./appid-configs/add-roles-template.json > ./$ADD_ROLE
		    OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
		    #echo $OAUTHTOKEN
		    result=$(curl -d @./$ADD_ROLE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/roles)
	*/

	url := fmt.Sprintf("%s%s", managementUrl, "/roles")
	jsonPayload := []byte(fmt.Sprintf("%s%s%s%s", "{\"name\": \"tenant_user_access\",\"description\": \"This is an example role.\",\"access\": [{\"application_id\": \"", clientId, "\",", "\"scopes\": [\"tenant_scope\"]}]}"))

	_, err := doHttpPost(jsonPayload, url, ibmCloudApiKey, ctx)
	if err != nil {
		return err
	}
	return nil
}

func addUsers(managementUrl string, ibmCloudApiKey string, ctx context.Context) error {
	/*
			OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
		    result=$(curl -d @./$USER_IMPORT_FILE -H "Content-Type: application/json" -X POST -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/cloud_directory/import?encryption_secret=$ENCRYPTION_SECRET)
	*/

	url := fmt.Sprintf("%s%s", managementUrl, "/cloud_directory/import?encryption_secret=12345678")
	jsonPayload := []byte("{\"itemsPerPage\":1,\"totalResults\":1,\"users\":[{\"scimUser\":{\"originalId\":\"7cdf7ac3-371f-4b4c-8d0a-81e479ab449b\",\"name\":{\"givenName\":\"Thomas\",\"familyName\":\"Example\",\"formatted\":\"Thomas Example\"},\"displayName\":\"Thomas Example\",\"active\":true,\"emails\":[{\"value\":\"thomas@example.com\",\"primary\":true}],\"passwordHistory\":[{\"passwordHash\":\"L6EEYnQANBPSBF0tDCPDZl4uVD07H3Ur8qIVynB1Ht4Bn4s/x0lA6kvyJxEPr/06m5hi5wdLM45JtYDlT8M0hjVIBI3YpXRR9J4oXZA/Yt/V13yjsUPsXKek6RWdOKWp+wuD5w3Bobh43QbRR3dXFoKUbcLVWQoKLWqvRATMQis=\",\"hashAlgorithm\":\"PBKDF2WithHmacSHA512\"}],\"status\":\"CONFIRMED\",\"passwordExpirationTimestamp\":0,\"passwordUpdatedTimestamp\":0,\"mfaContext\":{}},\"passwordHash\":\"L6EEYnQANBPSBF0tDCPDZl4uVD07H3Ur8qIVynB1Ht4Bn4s/x0lA6kvyJxEPr/06m5hi5wdLM45JtYDlT8M0hjVIBI3YpXRR9J4oXZA/Yt/V13yjsUPsXKek6RWdOKWp+wuD5w3Bobh43QbRR3dXFoKUbcLVWQoKLWqvRATMQis=\",\"passwordHashAlg\":\"PBKDF2WithHmacSHA512\",\"profile\":{\"attributes\":{}},\"roles\":[\"tenant_user_access\"]}]}")

	_, err := doHttpPost(jsonPayload, url, ibmCloudApiKey, ctx)
	if err != nil {
		return err
	}
	return nil
}

func configureUiText(managementUrl string, ibmCloudApiKey string, tenantName string, ctx context.Context) error {
	/*
	   	sed "s+FRONTENDNAME+$FRONTEND_NAME+g" ./appid-configs/add-ui-text-template.json > ./$ADD_UI_TEXT
	       OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
	       echo "PUT url: $MANAGEMENTURL/config/ui/theme_txt"
	       result=$(curl -d @./$ADD_UI_TEXT -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_text)
	*/

	url := fmt.Sprintf("%s%s", managementUrl, "/config/ui/theme_text")
	jsonPayload := []byte(fmt.Sprintf("%s%s%s", "{\"tabTitle\": \"Login to ", tenantName, "\", \"footnote\": \"Powered by the EMEA - Hybrid Cloud Build Team\"}"))

	_, err := doHttpPut(jsonPayload, url, ibmCloudApiKey, ctx)
	if err != nil {
		return err
	}
	return nil
}

func configureUiColour(managementUrl string, ibmCloudApiKey string, ctx context.Context) error {
	/*
		OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
			echo "PUT url: $MANAGEMENTURL/config/ui/theme_color"
			result=$(curl -d @./$ADD_COLOR -H "Content-Type: application/json" -X PUT -H "Authorization: Bearer $OAUTHTOKEN" $MANAGEMENTURL/config/ui/theme_color)
	*/

	url := fmt.Sprintf("%s%s", managementUrl, "/config/ui/theme_color")
	jsonPayload := []byte("{\"headerColor\": \"#008b8b\"}")

	_, err := doHttpPut(jsonPayload, url, ibmCloudApiKey, ctx)
	if err != nil {
		return err
	}
	return nil

}

func configureUiImage(managementUrl string, ibmCloudApiKey string, ctx context.Context) error {
	/*
	   	OAUTHTOKEN=$(ibmcloud iam oauth-tokens | awk '{print $4;}')
	       echo "POST url: $MANAGEMENTURL/config/ui/media?mediaType=logo"
	       result=$(curl -F "file=@./$ADD_IMAGE" -H "Content-Type: multipart/form-data" -X POST -v -H "Authorization: Bearer $OAUTHTOKEN" "$MANAGEMENTURL/config/ui/media?mediaType=logo")
	*/

	url := fmt.Sprintf("%s%s", managementUrl, "/config/ui/media?mediaType=logo")
	log := ctrllog.FromContext(ctx)

	//Download the image file from GitHub
	fileUrl := "https://raw.githubusercontent.com/IBM/multi-tenancy/main/installapp/appid-images/logo.png"
	err := downloadFile("/tmp/logo.png", fileUrl)
	if err != nil {
		return err
	}

	/*extraParams := map[string]string{
		"title":       "A",
		"author":      "A",
		"description": "A",
	}*/

	//request, err := newfileUploadRequest2(url, "file", "/tmp/logo.png")

	request, err := newfileUploadRequest(url, "file", "/tmp/logo.png")

	if err != nil {
		return err
	}
	client := &http.Client{}

	oauth, err := getIbmCloudOauthToken(ibmCloudApiKey, ctx)
	if err != nil {
		log.Error(err, "Error retrieving IBM Cloud Oauth token")
		return err
	}
	bearer := fmt.Sprintf("%s%s", "Bearer ", oauth)

	request.Header.Set("Authorization", bearer)

	//dump, _ := httputil.DumpRequest(request, true)
	//fmt.Println(string(dump))

	dump, _ := httputil.DumpRequestOut(request, true)
	fmt.Println(string(dump))

	resp, err := client.Do(request)

	if err != nil {
		return err
	}

	log.Info(fmt.Sprintf("%s%s", "response Status:", resp.Status))
	log.Info(fmt.Sprintf("%s%s", "response Headers:", resp.Header))
	respBody, _ := ioutil.ReadAll(resp.Body)
	log.Info(fmt.Sprintf("%s%s", "returning body=", string(respBody)))

	return nil
}

func doHttpGet(url string, ibmCloudApiKey string, ctx context.Context) ([]byte, error) {

	log := ctrllog.FromContext(ctx)
	var body []byte
	client := &http.Client{}

	log.Info(fmt.Sprintf("%s%s", "url=", url))

	oauth, err := getIbmCloudOauthToken(ibmCloudApiKey, ctx)
	if err != nil {
		log.Error(err, "Error retrieving IBM Cloud Oauth token")
		return body, err
	}

	bearer := fmt.Sprintf("%s%s", "Bearer ", oauth)

	req, err := http.NewRequest("GET", url, nil)
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

	body, _ = ioutil.ReadAll(resp.Body)

	log.Info(fmt.Sprintf("%s%s", "returning body=", string(body)))
	return body, nil

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

func doHttpPut(jsonPayload []byte, url string, ibmCloudApiKey string, ctx context.Context) ([]byte, error) {

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

	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonPayload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", bearer)

	resp, err := client.Do(req)
	if err != nil {
		log.Error(err, "Create PUT request failed")
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

func downloadFile(filepath string, url string) error {

	// Get the data
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Create the file
	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()

	// Write the body to file
	_, err = io.Copy(out, resp.Body)
	return err
}

/*func newfileUploadRequestOld(uri string, paramName, path string) (*http.Request, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	fileContents, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, err
	}
	fi, err := file.Stat()
	if err != nil {
		return nil, err
	}
	file.Close()

	body := new(bytes.Buffer)
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile(paramName, fi.Name())
	if err != nil {
		return nil, err
	}
	part.Write(fileContents)

	err = writer.Close()
	if err != nil {
		return nil, err
	}

	request, err := http.NewRequest("POST", uri, body)

	//request.Header.Set("Content-Type", writer.FormDataContentType())
	request.Header.Set("Content-Type", "multipart/form-data")
	request.Header.Set("Content-Type", "image/png")

	//request.Header.Add("Content-Length", strconv.Itoa(len(writer)))

	return request, nil
}*/

func newfileUploadRequest(uri string, paramName string, path string) (*http.Request, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile(paramName, filepath.Base(path))
	if err != nil {
		return nil, err
	}
	_, err = io.Copy(part, file)

	/*for key, val := range params {
		_ = writer.WriteField(key, val)
	}*/
	err = writer.Close()
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", uri, body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	//req.Header.Set("Content-Type", "multipart/form-data")
	req.Header.Set("Content-Type", "image/png")

	return req, err
}

func AppendRedirectUrl(managementUrl string, ibmCloudApiKey string, newRedirctUri string, ctx context.Context) error {

	type appIdRedirectUris struct {
		RedirectUris []string `json:"redirectUris"`
	}

	var jsonData appIdRedirectUris

	log := ctrllog.FromContext(ctx)

	url := fmt.Sprintf("%s%s", managementUrl, "/config/redirect_uris")

	resp, err := doHttpGet(url, ibmCloudApiKey, ctx)

	if err != nil {
		return err
	} else {
		// Retrieve existing Redirect URIs
		err = json.Unmarshal(resp, &jsonData)
		if err != nil {
			log.Error(err, "unmarshall error")
			return err
		}

		jsonData.RedirectUris = append(jsonData.RedirectUris, newRedirctUri)
		jsonData.RedirectUris = append(jsonData.RedirectUris, "http://ibm.com")

		//input := "golang, elixir, python, java"
		//tags := strings.Split(input, ",")

		joined := strings.Join(jsonData.RedirectUris[:], ",")

		//jsonPayload := []byte(fmt.Sprintf("%s%s%s%s", "{\"redirectUris\":[", joined, "]", ", \"additionalProp1\":}"))
		jsonPayload := []byte(fmt.Sprintf("%s%s%s%s", "{\"redirectUris\":[", joined, "]", "}"))

		_, err := doHttpPut(jsonPayload, url, ibmCloudApiKey, ctx)

		if err != nil {
			return err
		}

	}

	return nil

}
