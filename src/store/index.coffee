import Vue from 'vue'
import Vuex from 'vuex'
import PouchDB from 'pouchdb-browser'

import mutations from './mutations'
import actions from './actions'

_ = require 'lodash'

Vue.use(Vuex)

export default new Vuex.Store
  state:
    entries: []
    loading: false
    saving: false
    db_loaded: false
  mutations: mutations
  actions: actions
