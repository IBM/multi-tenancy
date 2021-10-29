import Vue from "vue";
import Vuex from "vuex";

const COMMAND_STATUS_INVOKED = "Invoked"
const COMMAND_STATUS_SUCCESS = "Success"
const COMMAND_STATUS_ERROR = "Error"

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    authenticationEnabled: "authentication-enabled-no",
    products: [],
    categories: [],
    commands: [],
    appid_init: {
      appid_clientId: " ",
      appid_discoveryEndpoint: " "
    },
    user: {
      isAuthenticated: false,
      name: "",
      idToken: "",
      accessToken: ""
    }
  },
  mutations: {
    setAppID(state, payload) {
      state.appid_init.appid_clientId = payload.appid_clientId;
      state.appid_init.appid_discoveryEndpoint = payload.appid_discoveryEndpoint;
    },
    logout(state) {
      state.user.isAuthenticated = false;
      state.user.name = "";
      state.user.idToken = "";
      state.user.accessToken = "";
    },
    login(state, payload) {
      state.user.isAuthenticated = true;
      state.user.idToken = payload.idToken;
      state.user.accessToken = payload.accessToken;
      state.user.name = payload.name;
    },
    sendCommand(state, payload) {
      payload.status = COMMAND_STATUS_INVOKED;
      state.commands.push(payload)
    },
    commandResponseReceived(state, payload) {
      if (state.commands) {
        state.commands.forEach((command) => {
          if (command.commandId == payload.commandId) {
            if (payload.successful == true) {
              command.status = COMMAND_STATUS_SUCCESS
            }
            else {
              command.status = COMMAND_STATUS_ERROR
            }                  
          }
        });
      }    
    },
    addProducts(state, payload) {
      state.products = payload;
    },
    addCategories(state, payload) {
      state.categories = payload;
    },
  },
  actions: {}
});
