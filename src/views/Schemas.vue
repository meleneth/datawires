<template lang="pug">
  div
    md-icon done
    h1(v-if="schemas") Schemas - {{ schemas[0].key[0]}}
    ul
      li(v-for="schema in schemas")
        router-link(:to="{name: 'Documents', params: {domain: schema.key[0], path: schema.key[1]}}") {{ schema.key[1] }}
        | {{ schema.value }}
</template>
<script lang="coffee">
_ = require 'lodash'
export default
  name: 'Schemas'
  data: ->
    return
      schemas: []
  created: ->
    @$store.dispatch "db_get_schemas"
      .then (d) =>
        @schemas = d
</script>
