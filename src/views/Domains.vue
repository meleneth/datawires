<template lang="pug">
add-schema
p
h2 Domains
table
  tr(v-for="domain in domains" :key="domain.key[0]")
    td
      | [
      router-link(:to="{name: 'Export', params: {domain: domain.key[0]}}") Export
      | ] &nbsp;
    td
      | {{ domain.value }}
    td
      router-link(:to="{name: 'Schemas', params: {domain: domain.key[0]}}") {{ domain.key[0] }}
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
  mounted: ->
    @$store.dispatch 'set_page_title', "Domains"
  created: ->
    @$store.dispatch "db_get_domains"
      .then (d) =>
        @domains = d
</script>
