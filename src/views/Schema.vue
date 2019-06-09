<template lang="pug">
  div
    | Schema HOT AND FRESH SCHEMA
    | {{ schema }}
    p(v-if="schema.dw$schema") {{ schema.dw$schema }}
    hr
    | {{ docs }}
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
          #@$forceUpdate()
  computed:
    docs: ->
      results = []
      if @schema
        for s in @$store.state.entries
          if s.dw$ref && s.dw$ref == @schema.dw$schema
            results.push s
      results

</script>
