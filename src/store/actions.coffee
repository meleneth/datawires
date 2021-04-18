import Vue from 'vue'
import Vuex from 'vuex'
import PouchDB from 'pouchdb-browser'
import 'axios'

_ = require 'lodash'

#PouchDB.plugin require 'pouchdb-authentication'

db_url = "http://tyreen.sectorfour:5984/datawires"
#db_url = "http://172.16.0.122:5984/noodatawires"
#db_options =
#  "auth.username": "datawires"
#  "auth.password": "datawires"
#db = new PouchDB db_url, {skip_setup: true}
#db.logIn "datawires", "datawires"
#  .then ->
#    console.log "I'm batman"
#db = new PouchDB db_url, {
#  auth:
#    username: "datawires"
#    password: "datawires"
#}
db = new PouchDB db_url

parse_ref = (ref) ->
  matches = ref.match "http:\/\/([^/]*)\/([^#]*)#"
  return [matches[1], matches[2]]

actions =
  save_entry: (context, doc) ->
    context.commit "SET_SAVING", true
    db.put doc
      .then (result) ->
        db.get result.id
          .then (result) ->
            context.commit "SET_ENTRY", result
            context.commit "SET_SAVING", false
  db_get_url: (context, url) ->
    return axios.get "#{db_url}#{url}"
  get_doc: (context, id) ->
    return db.get(id)
  db_get_domains: ->
    return @dispatch 'db_get_url', "/_design/schemas/_view/schemas?group_level=1"
      .then (d) ->
        return d.data.rows
  db_get_schemas: () ->
    return @dispatch 'db_get_url', "/_design/schemas/_view/schemas?group_level=2"
      .then (d) ->
        return d.data.rows
  db_get_documents: (context, key) ->
    return db.query "schemas/documents", {key: key, include_docs: true, reduce: false}
      .then (d) ->
        return _.map d.rows, (f) -> f.doc
  getSchemaByKey: (context, key) ->
    return @dispatch 'db_get_url', "/_design/schemas/_view/schemas?keys=%5B%5B%22#{key[0]}%22%2C%20%22#{key[1]}%22%5D%5D&include_docs=true&reduce=false"
      .then (d) ->
        return d.data.rows[0].doc
  getSchemasByDomain: (context, domain) ->
    return @dispatch 'db_get_url', "/_design/schemas/_view/schemas?include_docs=true&start_key=%5B%22#{ domain }%22%2C%20%22aaaaa%22%5D&end_key=%5B%22#{domain}%22%2C%20%22zzzzz%22%5D&skip=0&limit=21&reduce=false"
      .then (d) ->
        return _.map d.data.rows, (d) -> d.doc
  getDocumentsByRef: (context, ref) ->
    key = parse_ref ref
    return @dispatch 'db_get_url', "/_design/schemas/_view/documents?keys=%5B%5B%22#{key[0]}%22%2C%20%22#{key[1]}%22%5D%5D&include_docs=true&reduce=false"
      .then (d) ->
        return _.map d.data.rows, (d) -> d.doc
  getSchemaByRef: (context, ref) ->
    key = parse_ref ref
    return @dispatch 'db_get_url', "/_design/schemas/_view/schemas?keys=%5B%5B%22#{key[0]}%22%2C%20%22#{key[1]}%22%5D%5D&include_docs=true&reduce=false"
      .then (d) ->
        return d.data.rows[0].doc
  get: (context, id) ->
    @dispatch 'load_db'
      .then ->
        new Promise (resolve, reject) ->
          for entry in context.state.entries
            if id == entry._id
              return resolve JSON.parse JSON.stringify entry
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
  post_entry: (context, entry) ->
    db.post entry
  add_entry: (context, entry) ->
    db.post entry
      .then (result) ->
        context.commit 'SET_LOADING', true
        db.get result.id
          .then (result) ->
            context.commit 'ADD_ENTRY', result
            context.commit 'SET_LOADING', false

export default actions
