<template lang="pug">
div
  h2 SubDomains - {{ selected_domain }}
  ul
    li(v-for="domain in subDomains")
      a(@click="navigate($event, domain)") {{ domain }}
</template>
<script lang="coffee">
pointer = require 'json-pointer'
import EventBus from '@/components/Domains/EventBus'
export default 
  name: 'SubDomains'
  props:
    domains: Array
    selected_domain: String
  methods:
    navigate: (evt, domain) ->
      evt.preventDefault()
      EventBus.emit('selectSubDomain', {domain: domain})
  computed:
    subDomains: ->
      selected_domain = @selected_domain
      domains = _.filter @domains, (d) -> d.basedomain == selected_domain
      subdomains = _.map domains, (d) -> d.domain
      _.uniq subdomains
</script>
