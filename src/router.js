import Vue from 'vue'
import Router from 'vue-router'
import Home from './views/Home.vue'
import Document from './views/Document.vue'
import Domain from './views/Domain.vue'
import Domains from './views/Domains.vue'
import Schema from './views/Schema.vue'
import SchemaEdit from './views/SchemaEdit.vue'

import ObjectEdit from './components/SchemaEdit/ObjectEdit.vue'
import StringEdit from './components/SchemaEdit/StringEdit.vue'
import ArrayEdit from './components/SchemaEdit/ArrayEdit.vue'
import NumberEdit from './components/SchemaEdit/NumberEdit.vue'

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
    { path: '/schema/:id/edit', component: SchemaEdit, props: true,
      children: [
        { path: "/schema/:id/editObject", name: "ObjectEdit", component: ObjectEdit, props: true },
        { path: "/schema/:id/editString", name: "StringEdit", component: StringEdit, props: true },
        { path: "/schema/:id/editArray", name: "ArrayEdit", component: ArrayEdit, props: true },
        { path: "/schema/:id/editNumber", name: "NumberEdit", component: NumberEdit, props: true }
      ]
    },
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
