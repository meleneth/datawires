<template lang="pug">
  div
    h2 Schemas - {{ selected_domain }}
    ul
      li(v-for="schema in schemas")
        router-link(:to="{name: 'Schema', params: {id: schema.id}}") {{ schema.name }}
</template>
<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'Schemas'
  props:
    domains: Array
    selected_domain: String
  methods:
    navigate: (evt, domain) ->
      evt.preventDefault()
      EventBus.$emit('selectSubDomain', {domain: domain})
  computed:
    schemas: ->
      selected_domain = @selected_domain
      _.filter @domains, (d) -> d.domain == selected_domain
</script>
