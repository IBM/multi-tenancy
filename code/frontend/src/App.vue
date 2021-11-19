<template>
  <div>
  <div style="display: flex;flex-direction: row;">
    <div id="app" style="order: 1;flex-grow: 2;max-width: 300px;width:300px">
    <!-- Headerline -->
    <header class="mdc-top-app-bar mdc-top-app-bar--fixed">
        <div class="mdc-top-app-bar__row" style="background: DarkCyan;">
          <section class="mdc-top-app-bar__section mdc-top-app-bar__section--align-start">
            <span class="mdc-top-app-bar__title" style="color:white;">{{ headline }}</span>
            <button class="material-icons mdc-top-app-bar__action-item mdc-icon-button" aria-label="Reload" v-on:click="onLoadProductsAndCategoriesClicked()">
               <span class="material-icons">refresh</span>
            </button>
          </section>
          <section class="mdc-top-app-bar__section mdc-top-app-bar__section--align-end" role="toolbar">
            <button class="material-icons mdc-top-app-bar__action-item mdc-icon-button" aria-label="Your Account" v-on:click="onLoginClicked()">
              <span class="material-icons">account_circle</span>
            </button>
            <div v-if="isAuthenticated == true">{{ getUserName() }}</div>
            <button class="material-icons mdc-top-app-bar__action-item mdc-icon-button" aria-label="Logout" v-on:click="onLogoutClicked()">logout</button>
          </section>
        </div>
    </header>
    <main class="mdc-top-app-bar--dense-fixed-adjust">
    </main>

    
    <!-- Content -->
    <md-app>
      <md-app-drawer md-permanent="full" style="width: 240px;">
        <br>
        <md-list v-if="isAuthenticated == true">
          <md-list-item to="/catalog" exact>
            <md-icon style="margin-right: 10px;">explore</md-icon>
            <span class="md-list-item-text">Catalog</span>
          </md-list-item>

          <div
            v-for="category in this.categoriesWithSubCategories"
            :key="category.name"
            class=""
          >
          <md-list-item style="margin-left:50px">
            <span class="md-list-item-text">{{ category.name }}</span>
          </md-list-item>
            <div
              style="padding-left: 50px"
              v-for="subCategory in category.subCategories"
              :key="subCategory.id"
              class=""
            >
              <md-list-item @click="loadProducts(subCategory.id, subCategory.name)" style="padding-left:0px" exact>
                <md-icon style="margin-right: 10px;">explore</md-icon>
                <span class="md-list-item-text">{{ subCategory.name }}</span>
              </md-list-item>
            </div>
          </div>

          <md-list-item to="/order" exact
            ><md-icon style="margin-right: 10px;">add_shopping_cart</md-icon>
            <span class="md-list-item-text"
              >Shopping Cart ({{ amountLineItems }})</span
            >
          </md-list-item>
          <md-list-item to="/account" exact>
            <md-icon style="margin-right: 10px;">settings</md-icon>
            <span class="md-list-item-text">Account</span>
          </md-list-item>
        </md-list>
      </md-app-drawer>
    </md-app>
    </div>
    <div id="catalog" style="order: 2; flex-grow: 10;left: 320px;position: fixed;" v-if="isAuthenticated == true">
    <Catalog></Catalog>
    </div>
    <div id="order" style="order: 2; flex-grow: 10;left: 320px;position: fixed;" v-if="isAuthenticated == true"></div>
    <div id="account" style="order: 2; flex-grow: 10;left: 320px;position: fixed;"></div>
  </div>
  </div>
</template>

<script>
import Messaging from "./messaging.js";
import Catalog from "./Catalog.vue";
import "@material/mwc-top-app-bar-fixed";
import axios from "axios";
export default {
  name: "app",
  components: {
    Catalog
  },
  computed: {
    isAuthenticated() {
      return this.$store.state.user.isAuthenticated;
    }
  },
  data() {
    return {
      categories: {},
      categoriesWithSubCategories: {},
      loadingCategories: false,
      amountLineItems: 0,
      apiUrlCategories: window.VUE_APP_API_URL_CATEGORIES,
      apiUrlOrders: window.VUE_APP_API_URL_ORDERS,
      headline: window.VUE_APP_HEADLINE
    };
  },
  created() {
    
    let observable = Messaging.getObservable(
        Messaging.MICRO_FRONTEND_NAVIGATOR
    );
    observable.subscribe({
        next: (message) => {
          console.log(
            "navigator - App.vue - amountLineItems: " +
              message.payload.amountLineItems
          );
          this.amountLineItems = message.payload.amountLineItems;
        },
    });
    if (this.$store.state.user.isAuthenticated == true) {
      this.readCategories();
    }
  },
  methods: {
    onLoginClicked(){
      this.$router.push("/").catch(()=>{});
      window.location.reload(); 
    },
    onLogoutClicked(){
      this.$store.commit("logout");
      window.location.reload();
    },
    getUserName() {
      return this.$store.state.user.name;
    },
    onLoadProductsAndCategoriesClicked(){
      console.log("--> log onLoadProductsClicked : ");
      var categoryId = 2;   
      this.loadProducts( categoryId, "products");
      this.readCategories();
    },   
    loadProducts (categoryId, categoryName) {
      console.log("--> log loadProducts : ", categoryId, categoryName);
    
      let commandId = Date.now();
      let message = {
        topic: Messaging.TOPIC_NAVIGATOR_CATEGORY_CHANGED,
        commandId: commandId,
        payload: {
          categoryId: categoryId,
          categoryName: categoryName
        },
      };
      Messaging.send(message);
      this.$router.push('/catalog').catch(()=>{});
    },
    readCategories() {
  
      console.log("--> log readCategories : ", this.apiUrlCategories);
      if (this.loadingCategories == false) {
        this.loadingCategories = true;
        const axiosService = axios.create({
          timeout: 30000,
          headers: {
            "Content-Type": "application/json",
            Authorization: "Bearer " + this.$store.state.user.accessToken
          }
        });
        let that = this;
        axiosService
        .get(this.apiUrlCategories)
        .then(function(response) {
            console.log("--> log: Categories response : " + JSON.stringify(response));
            that.loadingCategories = false;
            that.categories = response.data;
            console.log("--> log: Categories data : " + JSON.stringify(that.categories));
            that.convertFromParentsToSubCategories(that.categories);
          })
          .catch(function(e) {
            var error="--> log: Can't load categories: " + e ;
            that.loadingCategories = false;
            console.error(error);
            that.$store.commit("logout");
          });
      }
    },
    convertFromParentsToSubCategories(inputJson) {
      // From: 
      // [{"id":13,"name":"Cellphones","parent":10},{"id":10,"name":"Electronics","parent":null},
      // {"id":1,"name":"Entertainment","parent":null},{"id":4,"name":"Games","parent":1},{"id":2,"name":"Movies","parent":1}]
      // To:
      // [{"id":10,"name":"Electronics", "subCategories": [{"id":13,"name":"Cellphones"}]}, 
      // {"id":1,"name":"Entertainment", "subCategories": [{"id":4,"name":"Games"}, {"id":2,"name":"Movies"}]}
      let output = []
      console.log("--> log: convertFromParentsToSubCategories ", JSON.stringify(inputJson));
      inputJson.forEach(category => {        
        if (category.parent == null) {
          output.push({
            "id": category.id,
            "name": category.name,
            "subCategories": []
          })
        }
      });
      
      output.forEach(mainCategory => {
        inputJson.forEach(category => {
          if (category.parent == mainCategory.id) {
            mainCategory.subCategories.push(category)
          }
        });    
      });
    
      this.categoriesWithSubCategories = output
    }
  },
};
</script>
