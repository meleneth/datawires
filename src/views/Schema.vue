<template lang="pug">
  div
    p(v-if="schema.dw$schema") {{ schema.dw$schema }}
      router-link(:to="{name: 'SchemaEdit', params: {id: schema._id}}")
        md-button.md-primary Edit
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
          if s.dw$ref && s.dw$ref == @schema.dw$schema
            results.push s
      results

</script>
