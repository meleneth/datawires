<template lang="pug">
  div
    h2 Root Domains
    ul
      li(v-for="domain in rootDomains")
        a(@click="navigate($event, domain)") {{ domain }}
</template>
<script lang="coffee">
pointer = require 'json-pointer'
import EventBus from '@/components/Domains/EventBus'
export default 
  name: 'RootDomains'
  props:
    domains: Array
  methods:
    navigate: (evt, domain) ->
      evt.preventDefault()
      EventBus.$emit('selectRootDomain', {domain: domain})
  computed:
    rootDomains: ->
      rootdomains = _.map @domains, (d) -> d.basedomain
      _.uniq rootdomains
</script>
