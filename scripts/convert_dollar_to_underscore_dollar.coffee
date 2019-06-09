PouchDB = require 'pouchdb-node'
_ = require 'lodash'

db = new PouchDB "http://clu:5984/vue_datawires"
db.allDocs({include_docs: true})
  .then (doc) =>
    entries = _.map doc.rows, (entry) -> entry.doc
    for entry in entries
      if entry.$schema
        entry.dw$schema = entry.$schema
        delete entry.$schema
      if entry.$ref
        entry.dw$ref = entry.$ref
        delete entry.$ref
      db.put entry
        .catch (e) ->
          console.log e

