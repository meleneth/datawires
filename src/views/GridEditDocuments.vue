<template lang="pug">
div
  h1
    | {{ domain }} / {{ path }} - gridEditDocuments
  table
    tr(v-for="row in rows")
      td(v-for="field in row")
        component(:is="field.is"
                  :current="field.current"
                  :path="field.path"
                  :doc="field.doc"
                  :description="field.description"
                  :title="field.title"
                  :property="field.property"
                  v-on:updateString="update_string"
                  v-on:updateNumber="update_number")
</template>

<script lang="coffee">
_ = require 'lodash'
pointer = require 'json-pointer'

import EventBus from '@/components/SchemaEdit/EventBus'
import StringEdit from '@/components/DocumentGridEdit/StringEdit.vue'
import NumberEdit from '@/components/DocumentGridEdit/NumberEdit.vue'

schema_to_fields = (schema, document) ->
  fields = []
  for name, property of schema.properties
    path = "/#{name}"
    if property.type == "string"
      editor = StringEdit
    if property.type == "number"
      editor = NumberEdit
    current = ''
    if pointer.has document, path
      current = pointer.get document, path
    fields.push
      current: current
      path: path
      is: editor
      doc: document
      description: property.description
      title: property.title
      property: property
  return fields

export default
  name: 'Documents'
  props:
    domain: String
    path: String
  data: ->
    documents: false
    schema: {}
  mounted: ->
    @$store.dispatch 'set_page_title', "GridEditDocuments"
    schema = "http://#{ @domain }/#{ @path }#"
#    http://172.16.0.122:5984/noodatawires/_design/schemas/_view/documents?keys=%5B%5B%22rpg.sec7or.com%22%2C%20%22item%22%5D%5D&skip=0&limit=21&reduce=false
    @$store.dispatch 'getSchemaByRef', schema
      .then (schema) =>
        console.log "Loaded schema from DB"
        console.log schema
        @schema = schema
        @$store.dispatch "db_get_documents", [@domain, @path]
          .then (d) =>
            @documents = d
  methods:
    update_string: (data) ->
      pointer.set data.doc, data.path, data.value
    update_number: (data) ->
      pointer.set data.doc, data.path, Number(data.value)
  computed:
    rows: ->
      rows = []
      for doc in @documents
        fields = schema_to_fields @schema, doc
        rows.push fields
      return rows
    docs: ->
      results = []
      if @schema
        for s in @$store.state.entries
          if s.$ref && s.$ref == @schema.$schema
            results.push s
      results

</script>
