import Vue from 'vue'
import Vuex from 'vuex'
import PouchDB from 'pouchdb-browser'

db = new PouchDB "http://clu:5984/vue_datawires"
_ = require 'lodash'

Vue.use(Vuex)

export default new Vuex.Store
  state:
    entries: []
    loading: false
    saving: false
    db_loaded: false
  ,
  mutations:
    ADD_ENTRY: (state, entry) ->
      state.entries.push entry
    SET_ENTRIES: (state, entries) ->
      state.entries = entries
    SET_ENTRY: (state, entry) ->
      for value, index in state.entries
        if value._id == entry._id
          state.entries[index] = entry
          return
    SET_LOADING: (state, loading) ->
      state.loading = loading
    SET_DBLOADED: (state, db_loaded) ->
      state.db_loaded = db_loaded
    SET_SAVING: (state, saving) ->
      state.saving = saving
  ,
  actions:
    save_entry: (context, doc) ->
      context.commit "SET_SAVING", true
      db.put doc
        .then (result) ->
          db.get result.id
            .then (result) ->
              context.commit "SET_ENTRY", result
              context.commit "SET_SAVING", false
    get: (context, id) ->
      @dispatch 'load_db'
        .then ->
          new Promise (resolve, reject) ->
            for entry in context.state.entries
              if id == entry._id
                return resolve(entry)
            reject Error "Could not find db entry for id #{id}"
    load_db: (context) ->
      if context.state.db_loaded
        return context.state.db_loaded
      context.commit 'SET_LOADING', true
      p = db.allDocs({include_docs: true})
      p = p.then (doc) =>
          entries = _.map doc.rows, (entry) -> entry.doc
          context.commit 'SET_ENTRIES', entries
          context.commit 'SET_LOADING', false
      context.commit 'SET_DBLOADED', p
      p
    add_entry: (context, entry) ->
      db.post entry
        .then (result) ->
          context.commit 'SET_LOADING', true
          db.get result.id
            .then (result) ->
              context.commit 'ADD_ENTRY', result
              context.commit 'SET_LOADING', false
