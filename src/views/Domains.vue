<template lang="pug">
  div
    md-icon done
    | Domains
    ul
      li(v-for="domain in domains")
        router-link(:to="{name: 'Schemas', params: {domain: domain.key[0]}}") {{ domain.key[0] }}
        | {{ domain.value }}
</template>
<script lang="coffee">
_ = require 'lodash'
export default
  name: 'Domains'
  data: ->
    return
      domains: []
  created: ->
    @$store.dispatch "db_get_domains"
      .then (d) =>
        @domains = d
</script>
