<template lang="pug">
  div
    add-schema
    md-icon done
    h1(v-if="schemas") Schemas - {{ domain }}
    ul
      li(v-for="schema in schemas")
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
  created: ->
    @$store.dispatch "db_get_schemas"
      .then (d) =>
        @schemas = d
</script>
