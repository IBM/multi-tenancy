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

func GetClientId(managementUrl string, ibmCloudApiKey string, ctx context.Context) (string, error) {

	//$ curl -X POST     "https://iam.cloud.ibm.com/identity/token"     -H "content-type: application/x-www-form-urlencoded"     -H "accept: application/json"     -d 'grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=<API_KEY>' > token.json

	/*APPID_MANAGEMENT_URL_ALL_APPLICATIONS=${APPID_MANAGEMENT_URL}/applications
	echo $APPID_MANAGEMENT_URL_ALL_APPLICATIONS
	result=$(curl -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTHTOKEN" $APPID_MANAGEMENT_URL_ALL_APPLICATIONS)
	echo $result
	APPID_CLIENT_ID=$(echo $result | sed -n 's|.*"clientId":"\([^"]*\)".*|\1|p')
	echo $APPID_CLIENT_ID*/

	log := ctrllog.FromContext(ctx)

	//clientId := ""
	oauth, err := getIbmCloudOauthToken(ibmCloudApiKey, ctx)
	if err != nil {
		log.Error(err, "Error retrieving IBM Cloud Oauth token")
		return "", err
	}

	client := &http.Client{}

	//appIdUrl := fmt.Sprintf("%s%s", managementUrl, "applications")
	//log.Info(fmt.Sprintf("%s%s", "appIdUrl=", appIdUrl))
	log.Info(fmt.Sprintf("%s%s", "managementUrl=", managementUrl))

	jsonPayload := fmt.Sprintf("%s%s", "name:", "")

	bearer := fmt.Sprintf("%s%s", "Bearer ", oauth)
	log.Info(fmt.Sprintf("%s%s", "bearer=", bearer))

	var jsonStr = []byte(jsonPayload)
	req, err := http.NewRequest("POST", managementUrl, bytes.NewBuffer(jsonStr))
	//req.Header.Set("X-Custom-Header", "myvalue")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", bearer)

	resp, err := client.Do(req)
	if err != nil {
		log.Error(err, "Create POST request failed")
		return "", err
	}
	defer resp.Body.Close()

	log.Info(fmt.Sprintf("%s%s", "response Status:", resp.Status))
	log.Info(fmt.Sprintf("%s%s", "response Headers:", resp.Header))
	//fmt.Println("response Status:", resp.Status)
	//fmt.Println("response Headers:", resp.Header)
	body, _ := ioutil.ReadAll(resp.Body)
	//fmt.Println("response Body:", string(body))

	log.Info(fmt.Sprintf("%s%s", "returning clientId=", string(body)))
	return string(body), nil

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

	//myJsonStr := `"{"access_token": "eyJraWQiOiIyMDIyMDIxNTA4MjMiLCJhbGciOiJSUzI1NiJ9.eyJpYW1faWQiOiJJQk1pZC0xMjAwMDBERjk4IiwiaWQiOiJJQk1pZC0xMjAwMDBERjk4IiwicmVhbG1pZCI6IklCTWlkIiwianRpIjoiNzhmZWYxODItMGJhYS00N2VjLTk2YzMtZDhhNzYxYWJjYTA5IiwiaWRlbnRpZmllciI6IjEyMDAwMERGOTgiLCJnaXZlbl9uYW1lIjoiQWRhbSIsImZhbWlseV9uYW1lIjoiZGUgTGVldXciLCJuYW1lIjoiQWRhbSBkZSBMZWV1dyIsImVtYWlsIjoiREVMRUVVV0BVSy5JQk0uQ09NIiwic3ViIjoiZGVsZWV1d0B1ay5pYm0uY29tIiwiYXV0aG4iOnsic3ViIjoiZGVsZWV1d0B1ay5pYm0uY29tIiwiaWFtX2lkIjoiSUJNaWQtMTIwMDAwREY5OCIsIm5hbWUiOiJBZGFtIGRlIExlZXV3IiwiZ2l2ZW5fbmFtZSI6IkFkYW0iLCJmYW1pbHlfbmFtZSI6ImRlIExlZXV3IiwiZW1haWwiOiJERUxFRVVXQFVLLklCTS5DT00ifSwiYWNjb3VudCI6eyJib3VuZGFyeSI6Imdsb2JhbCIsInZhbGlkIjp0cnVlLCJic3MiOiJjZjRkMzI5M2M0ZTU2ODIyM2ZkYjFiNDA4ZmZjZTc1MiIsImltc191c2VyX2lkIjoiOTQyMzQzNiIsImZyb3plbiI6dHJ1ZSwiaW1zIjoiMjAzMjM0MCJ9LCJpYXQiOjE2NDUxOTUzMjQsImV4cCI6MTY0NTE5ODkyNCwiaXNzIjoiaHR0cHM6Ly9pYW0uY2xvdWQuaWJtLmNvbS9pZGVudGl0eSIsImdyYW50X3R5cGUiOiJ1cm46aWJtOnBhcmFtczpvYXV0aDpncmFudC10eXBlOmFwaWtleSIsInNjb3BlIjoiaWJtIG9wZW5pZCIsImNsaWVudF9pZCI6ImRlZmF1bHQiLCJhY3IiOjMsImFtciI6WyJ0b3RwIiwibWZhIiwib3RwIiwicHdkIl19.We8uO7Vt8JDtl_Dv4-RhrJOn5VzW85hPVWCZCUZ6xzUatP8e_hpAZ3id0l1tLn81dODoLQS4mihxZzG6IAUWDZBHHu80JVNqr8er3UAQkzTATD7znrXkl6M1FCQquNTrCO33xUeWXKJWX26DrWpqgDaTBtSYxn9WYmoljApfhOg4EQeLs90Mpebm3KzPQaIQr1On6B9r_VX8xWPbCL7SmPOZwYTuKlYp36Zw70tHLTKEcCCtPfyVFMK9PRlGbgDnByDYQB6mHvvbY8y575zwDQrx-ykoXQoKpWdKx1teHDa11o48JY20lxO8FqJ-QS3ML1hrhqo92pWmq46i0Tbccg"}"`

	/*	"access_token": "eyJraWQiOiIyMDIyMDIxNTA4MjMiLCJhbGciOiJSUzI1NiJ9.eyJpYW1faWQiOiJJQk1pZC0xMjAwMDBERjk4IiwiaWQiOiJJQk1pZC0xMjAwMDBERjk4IiwicmVhbG1pZCI6IklCTWlkIiwianRpIjoiNzhmZWYxODItMGJhYS00N2VjLTk2YzMtZDhhNzYxYWJjYTA5IiwiaWRlbnRpZmllciI6IjEyMDAwMERGOTgiLCJnaXZlbl9uYW1lIjoiQWRhbSIsImZhbWlseV9uYW1lIjoiZGUgTGVldXciLCJuYW1lIjoiQWRhbSBkZSBMZWV1dyIsImVtYWlsIjoiREVMRUVVV0BVSy5JQk0uQ09NIiwic3ViIjoiZGVsZWV1d0B1ay5pYm0uY29tIiwiYXV0aG4iOnsic3ViIjoiZGVsZWV1d0B1ay5pYm0uY29tIiwiaWFtX2lkIjoiSUJNaWQtMTIwMDAwREY5OCIsIm5hbWUiOiJBZGFtIGRlIExlZXV3IiwiZ2l2ZW5fbmFtZSI6IkFkYW0iLCJmYW1pbHlfbmFtZSI6ImRlIExlZXV3IiwiZW1haWwiOiJERUxFRVVXQFVLLklCTS5DT00ifSwiYWNjb3VudCI6eyJib3VuZGFyeSI6Imdsb2JhbCIsInZhbGlkIjp0cnVlLCJic3MiOiJjZjRkMzI5M2M0ZTU2ODIyM2ZkYjFiNDA4ZmZjZTc1MiIsImltc191c2VyX2lkIjoiOTQyMzQzNiIsImZyb3plbiI6dHJ1ZSwiaW1zIjoiMjAzMjM0MCJ9LCJpYXQiOjE2NDUxOTUzMjQsImV4cCI6MTY0NTE5ODkyNCwiaXNzIjoiaHR0cHM6Ly9pYW0uY2xvdWQuaWJtLmNvbS9pZGVudGl0eSIsImdyYW50X3R5cGUiOiJ1cm46aWJtOnBhcmFtczpvYXV0aDpncmFudC10eXBlOmFwaWtleSIsInNjb3BlIjoiaWJtIG9wZW5pZCIsImNsaWVudF9pZCI6ImRlZmF1bHQiLCJhY3IiOjMsImFtciI6WyJ0b3RwIiwibWZhIiwib3RwIiwicHdkIl19.We8uO7Vt8JDtl_Dv4-RhrJOn5VzW85hPVWCZCUZ6xzUatP8e_hpAZ3id0l1tLn81dODoLQS4mihxZzG6IAUWDZBHHu80JVNqr8er3UAQkzTATD7znrXkl6M1FCQquNTrCO33xUeWXKJWX26DrWpqgDaTBtSYxn9WYmoljApfhOg4EQeLs90Mpebm3KzPQaIQr1On6B9r_VX8xWPbCL7SmPOZwYTuKlYp36Zw70tHLTKEcCCtPfyVFMK9PRlGbgDnByDYQB6mHvvbY8y575zwDQrx-ykoXQoKpWdKx1teHDa11o48JY20lxO8FqJ-QS3ML1hrhqo92pWmq46i0Tbccg",
		"refresh_token": "not_supported",
		"ims_user_id": 9423436, "token_type": "Bearer", "expires_in": 3600, "expiration": 1645198924,"scope": "ibm openid"*/

	log := ctrllog.FromContext(ctx)

	endpoint := "https://iam.cloud.ibm.com/identity/token"
	data := url.Values{}
	data.Set("grant_type", "urn:ibm:params:oauth:grant-type:apikey")
	//data.Set("apikey", "SgW-LUklPdRSw0p2VakbmTr9IaOUhmpUSOE-fLs8-1lL")
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
