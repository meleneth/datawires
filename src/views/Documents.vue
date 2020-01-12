<template lang="pug">
  div
    p {{ domain }}
    p {{ path }}
    ul
      li(v-for="doc in documents")
        router-link(:to="{name: 'Document', params: {id: doc._id}}") {{ doc.name || doc._id }}
</template>

<script lang="coffee">
_ = require 'lodash'

export default
  name: 'Documents'
  props:
    domain: String
    path: String
  data: ->
    documents: false
  mounted: ->
    schema = "http://#{ @domain }/#{ @path }#"
#    http://172.16.0.122:5984/noodatawires/_design/schemas/_view/documents?keys=%5B%5B%22rpg.sec7or.com%22%2C%20%22item%22%5D%5D&skip=0&limit=21&reduce=false
    console.log schema
    @$store.dispatch "db_get_documents", [@domain, @path]
      .then (d) =>
        @documents = d
  methods:
    load_schema: ->
      @$store.dispatch 'get', @id
        .then (schema) =>
          @schema = schema
  computed:
    docs: ->
      results = []
      if @schema
        for s in @$store.state.entries
          if s.$ref && s.$ref == @schema.$schema
            results.push s
      results

</script>
