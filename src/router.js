import Vue from 'vue'
import Router from 'vue-router'
import Home from './views/Home.vue'
import Document from './views/Document.vue'
import Domain from './views/Domain.vue'
import Domains from './views/Domains.vue'
import Schema from './views/Schema.vue'
import SchemaEdit from './views/SchemaEdit.vue'

Vue.use(Router)

export default new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    { path: '/', name: 'home', component: Home },
    { path: '/document/:id', name: 'Document', component: Document, props: true },
    { path: '/domain/:id', name: 'Domain', component: Domain, props: true },
    { path: '/domains', name: 'Domains', component: Domains, props: true },
    { path: '/schema/:id', name: 'Schema', component: Schema, props: true },
    { path: '/schema/:id/edit', name: 'SchemaEdit', component: SchemaEdit, props: true },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import(/* webpackChunkName: "about" */ './views/About.vue')
    }
  ]
})
