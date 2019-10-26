<template lang="pug">
  div
    md-icon done
    | Domains
    div
      component(:is="selectedComponent" :domains="domains" :selected_domain="selected_domain")
</template>
<script lang="coffee">
_ = require 'lodash'
import EventBus from '@/components/Domains/EventBus'
import RootDomains from '@/components/Domains/RootDomains'
import SubDomains from '@/components/Domains/SubDomains'
import Schemas from '@/components/Domains/Schemas'
export default
  name: 'Domains'
  data: ->
    selectedComponent: false
    selected_domain: false
  created: ->
    @selectedComponent = RootDomains
    EventBus.$on 'selectRootDomain', (data) =>
      @selected_domain = data.domain
      @selectedComponent = SubDomains
    EventBus.$on 'selectSubDomain', (data) =>
      @selected_domain = data.domain
      @selectedComponent = Schemas
  methods:
    select_domain: (name) ->
      @selected_domain = name
      @selected_basedomains = _.filter @domains, (d) => d.basedomain == @selected_domain
    select_basedomain: (name) ->
      @selected_domain = name
      @selected_basedomains = []
      @selected_domains = _.filter @domains, (d) => d.domain == @selected_domain
  computed:
    baseDomains: ->
      basedomains = _.map @domain_stats, (d) -> d.basedomain
      _.uniq basedomains
    uniqueDomains: ->
      domains = _.map @domains, (d) -> d.basedomain
      domains = _.uniq domains
      _.sortBy domains, (d) -> d
    domains: ->
      domain_names = {}
      for domain in @$store.state.entries
        if domain.dw$schema
          domain_names[domain.dw$schema] = domain._id
      domain_stats = []
      for key, value of domain_names
        pieces = key.match /^([^:]*):\/\/([^/]*)\/([^\#]*)#/
        domain_pieces = pieces[2].split /\./
        if domain_pieces.length > 1
          [..., base, extension] = domain_pieces
          basedomain = "#{base}.#{extension}"
        else
          basedomain = domain_pieces[0]
        domain_stats.push {name: key, id: value, domain: pieces[2], path: pieces[3], basedomain: basedomain}
      _.orderBy domain_stats, ['basedomain', 'domain']
</script>
