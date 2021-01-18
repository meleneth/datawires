<template lang="pug">
  v-container
    add-schema
    p
    h2 Domains
    v-row(v-for="domain in domains" :key="domain.key[0]")
      v-col
        | [
        router-link(:to="{name: 'Export', params: {domain: domain.key[0]}}") Export
        | ] &nbsp;
        router-link(:to="{name: 'Schemas', params: {domain: domain.key[0]}}") {{ domain.key[0] }}
        | {{ domain.value }}
</template>
<script lang="coffee">
_ = require 'lodash'
import AddSchema from  '@/components/AddSchema.vue'

export default
  name: 'Domains'
  components:
    "add-schema": AddSchema
  data: ->
    return
      domains: []
  created: ->
    @$store.dispatch "db_get_domains"
      .then (d) =>
        @domains = d
</script>
