import Vue from 'vue';
import Router from 'vue-router';
import App from './App.vue'

Vue.use(Router);

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'home',
      component: App
    },
    {
      path: '/loginwithtoken',
      name: 'loginwithtoken',
      component: App
    }
  ],
});