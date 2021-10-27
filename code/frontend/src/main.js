import Vue from 'vue'
import App from './App.vue'

Vue.config.productionTip = false

import VueMaterial from 'vue-material'
import 'vue-material/dist/vue-material.min.css'
import 'vue-material/dist/theme/default.css'
import store from './store'
import router from './router';
import AppID from 'ibmcloud-appid-js';


//import { MwcTopAppBarFixed } from 'vue-material/dist/components'
//Vue.use(MwcTopAppBarFixed)
//import { MdButton } from 'vue-material/dist/components'
//Vue.use(MdButton)

Vue.use(VueMaterial)

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
      console.log("--> log: update token ");
      
      let tokens = await appID.silentSignin();
      console.log("--> log: silentSignin tokens ", tokens);   
      user_info = {
        isAuthenticated: true,
        idToken : tokens.idToken,
        accessToken: tokens.accessToken
        // name : tokens.idTokenPayload.given_name
      }
      store.commit("login", user_info);
      console.log("--> log: silentSignin tokens ", tokens);
      console.log("--> log: username : " + store.state.user);   
      return true;
    } catch (e) {
      console.log("--> log: asyncAppIDrefresh - catch interval error ", e);
      user_info = {
        isAuthenticated: false,
        idToken : " ",
        accessToken: " ",
        name : " "
      }
      store.commit("login", user_info);
      console.log("--> log: username : " + store.state.user); 
      window.location.reload();
      return false;
    }
  } else {
    console.log("--> log: asyncAppIDrefresh - no refresh ");
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

  if (store.state.user.isAuthenticated == true) {
    console.log("--> log: user logged on : " + store.state.user); 
    renew_token=asyncAppIDrefresh(appID);
    console.log("--> log: renew_token : " + renew_token);
  } else {     
      user_info = {
        isAuthenticated: false,
        idToken : " ",
        accessToken: " ",
        name : " "
      }
      store.commit("login", user_info);
      console.log("--> log: user logged on username : " + store.state.user);  
  }
}, 1000000);

export { default as Messaging } from "./messaging.js";
