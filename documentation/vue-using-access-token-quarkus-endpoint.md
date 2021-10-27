# Vue.js using an `accesstoken` to invoke Quarkus endpoints

Here is one example invokation:

```html      
        <md-menu md-size="small" v-if="isAuthenticated == true">
            <md-button md-size="small" md-menu-trigger style="color:white;">{{ getUserName() }}<md-icon class="md-size-x">verified_user</md-icon></md-button>
            <md-menu-content>
              <md-menu-item v-on:click="onCheckTokenClicked()">Check token</md-menu-item>
              <md-menu-item v-on:click="onLogoutClicked()">Logout</md-menu-item>
            </md-menu-content>
        </md-menu>
...
```

Using the REST endpoint of the `articles service` only on the local machine to verify the accesstoken usage in Quarkus.

```javascript
...
import axios from "axios";
...
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
  ...
  methods: {
    onCheckTokenClicked(){
      const axiosService = axios.create({
      timeout: 30000, 
      headers: {
          "Content-Type": "application/json",
          Authorization: "Bearer " + this.$store.state.user.accessToken
        }
      });
      let that = this;
      let url = "http://localhost:8084/articlesA";
      console.log("--> log: readArticles URL : " + url);
      axiosService
        .get(url)
        .then(function(response) {
          that.articles = response.data;
          console.log("--> log: readArticles data : " + that.articles);
          that.loading = false;
          that.error = "";
        })
        .catch(function(error) {
          console.log("--> log: readArticles error: " + error);
          that.loading = false;
          that.error = error;
        });      
    },
```
