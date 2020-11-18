<template lang="pug">
  div
    p(v-if="schema.$schema") {{ schema.$schema }}
      router-link(:to="{name: 'SchemaEdit', params: {id: schema._id}}")
        v-btn Edit
    ul
      li(v-for="doc in docs")
        router-link(:to="{name: 'Document', params: {id: doc._id}}") {{ doc.name || doc._id }}
</template>

<script lang="coffee">
_ = require 'lodash'

export default
  name: 'Schema'
  props:
    id: String
  data: ->
    schema: false
  mounted: ->
    @load_schema()
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
