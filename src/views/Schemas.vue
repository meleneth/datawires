<template lang="pug">
  div
    add-schema
    h1(v-if="schemas") Schemas - {{ domain }}
    ul
      li(v-for="schema in filtered_schemas")
        | [
        router-link(:to="{name: 'SchemaEdit', params: {domain: schema.key[0], name: schema.key[1]}}") edit
        | ]
        router-link(:to="{name: 'Documents', params: {domain: schema.key[0], path: schema.key[1]}}") {{ schema.key[1] }}
        | {{ schema.value }}
</template>
<script lang="coffee">
_ = require 'lodash'
import AddSchema from  '@/components/AddSchema.vue'

export default
  name: 'Schemas'
  components:
    "add-schema": AddSchema
  props:
    domain: String
  data: ->
    return
      schemas: []
  computed:
    filtered_schemas: ->
      filtered =  _.filter @schemas, (d) => d.key[0] == @domain
      console.log "Filtered: "
      console.log filtered
      return filtered
  created: ->
    @$store.dispatch "db_get_schemas"
      .then (d) =>
        @schemas = d
</script>
