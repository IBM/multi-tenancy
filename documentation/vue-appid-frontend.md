# Using App ID in a Vue.js frontend

### Add App ID client SDK

* [App ID client SDK for Single WebPage](https://github.com/ibm-cloud-security/appid-clientsdk-js)
* [How to implement await in JavaScript](https://basarat.gitbook.io/typescript/future-javascript/async-await)
* [Client SDK JavaScript](https://ibm-cloud-security.github.io/appid-clientsdk-js/AppID.html#getUserInfo)

```sh
npm install ibmcloud-appid-js
```

To use refresh token, you need to enable refresh token, as you see in the image below.

![](./images/token-configuration.png)

### Use the App ID client SDK in Vue.js

Relevant code in the `main.js` file. 

The code is structured in :

1. Set variable for authentication
2. Functions 
    * Login (`appID.Signin()`)
    * Renew (`appID.silentSignin()`)
3. App ID authentication init
4. Create vue appilcation instance
5. Renew token in an interval (https://www.unixtimestamp.com/index.php)

```javascript
import AppID from 'ibmcloud-appid-js';
...
/**********************************/
/* Set variable for authentication
/**********************************/
let appid_init;
let user_info;

/**********************************/
/* Functions 
/**********************************/
async function asyncAppIDInit(appID) {

  var appID_init_Result = await appID.init(initOptions);
  console.log("--> log: appID_init_Result ", appID_init_Result);
  
  /**********************************/
  /* Check if the user is already authenticated
  /**********************************/
  if (!store.state.user.isAuthenticated) {
    try {
      /******************************/
      /* Authentication
      /******************************/
      
      let tokens = await appID.signin();
      console.log("--> log: tokens ", tokens);   
      user_info = {
        isAuthenticated: true,
        idToken : tokens.idToken,
        accessToken: tokens.accessToken,
        name : tokens.idTokenPayload.given_name
      }
      store.commit("login", user_info);
      return true;
    } catch (e) {
      console.log("--> log: error ", e);
      return false;
    }
  }
}

async function asyncAppIDrefresh(appID) {
  
  if ( store.state.user.isAuthenticated == true) {
    try {
      /******************************/
      /* Authentication
      /******************************/
      
      let tokens = await appID.silentSignin();
      console.log("--> log: silentSignin tokens ", tokens);   
      user_info = {
        isAuthenticated: true,
        idToken : tokens.idToken,
        accessToken: tokens.accessToken
        // name : tokens.idTokenPayload.given_name
      }
      store.commit("login", user_info);
      return true;
    } catch (e) {
      console.log("--> log: catch interval error ", e);
      return false;
    }
  } else {
    console.log("--> log: no refresh ");
    return false;
  }
}

/**********************************/
/* App ID authentication init
/**********************************/

appid_init = {
    //web-app-tenant-a-single
    appid_clientId: window.VUE_APPID_CLIENT_ID,
    appid_discoveryEndpoint: window.VUE_APPID_DISCOVERYENDPOINT
}

console.log("--> log: appid_init", appid_init);
store.commit("setAppID", appid_init);

let initOptions = {
    clientId: store.state.appid_init.appid_clientId , discoveryEndpoint: store.state.appid_init.appid_discoveryEndpoint
}

/**********************************/
/* Create vue appication instance
/**********************************/
let appID = new AppID();
let init_messsage = "";
if (!(init_messsage=asyncAppIDInit(appID))) {
    console.log("--> log: init_messsage : " + init_messsage);
    window.location.reload();
} else {
      console.log("--> log: init_messsage : " + init_messsage);
      // Vue application instance
      new Vue({
        store,
        router,
        render: h => h(App)
      }).$mount('#app')
}

/**********************************/
/* App ID authentication renew_token with silentSignin
/**********************************/
let renew_token;

setInterval(() => {
  console.log("--> log: token interval ");
  console.log("--> log: isAuthenticated ", store.state.user.isAuthenticated);

  if (store.state.user.isAuthenticated == false) {
    renew_token=asyncAppIDrefresh(appID);
    console.log("--> log: renew_token : " + renew_token);
  } else {
      console.log("--> log: renew_token : " + renew_token); 
      user_info = {
        isAuthenticated: false,
        idToken : " ",
        accessToken: " ",
        name : " "
      }
      store.commit("login", user_info);    
  }
}, 10000);
```