import Vue from 'vue'
import './plugins/axios'
import '@/assets/css/tailwind.css'
import App from './App.vue'
import router from './router'
import store from './store'

Vue.use(require('vue-moment'))

Vue.config.productionTip = false

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
