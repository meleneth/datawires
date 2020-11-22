import Admin from '@/views/Admin.vue'
import CreateDocument from '@/views/CreateDocument.vue'
import DataViewDemo from '@/views/DataViewDemo.vue'
import Document from '@/views/Document.vue'
import DocumentEdit from '@/views/DocumentEdit.vue'
import Documents from '@/views/Documents.vue'
import Domain from '@/views/Domain.vue'
import Domains from '@/views/Domains.vue'
import GridEditDocuments from '@/views/GridEditDocuments.vue'
import Home from '@/views/Home.vue'
import Router from 'vue-router'
import Schema from '@/views/Schema.vue'
import SchemaEdit from '@/views/SchemaEdit.vue'
import Schemas from '@/views/Schemas.vue'
import Vue from 'vue'

Vue.use(Router)

export default new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    { path: '/', name: 'home', component: Home },
    { path: '/admin', name: 'Admin', component: Admin },
    { path: '/dataviewdemo', name: 'DataViewDemo', component: DataViewDemo },
    { path: '/document/:id', name: 'Document', component: Document, props: true },
    { path: '/document/:id/edit', name: 'DocumentEdit', component: DocumentEdit, props: true },
    { path: '/domain/:domain', name: 'Domain', component: Domain, props: true },
    { path: '/domains', name: 'Domains', component: Domains, props: true },
    { path: '/schemas/:domain', name: 'Schemas', component: Schemas, props: true },
    { path: '/documents/:domain/:path', name: 'Documents', component: Documents, props: true },
    { path: '/documents/:domain/:path/gridEdit', name: 'GridEditDocuments', component: GridEditDocuments, props: true },
    { path: '/schema/:domain/:name', name: 'Schema', component: Schema, props: true },
    { path: '/schema/:domain/:name/createDocument', name: 'CreateDocument', component: CreateDocument, props: true },
    { path: '/schema/:domain/:name/edit', name: 'SchemaEdit', component: SchemaEdit, props: true },
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
