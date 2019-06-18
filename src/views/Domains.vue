<template lang="pug">
  div
    | Domains
    ul
      li(v-for="domain in uniqueDomains") {{ domain }}
    md-button.md-raised.md-primary(v-on:click='select_domain("TIGER")') Primary
    hr
    ul
      li(v-for="domain in domains")
        router-link(:to="{name: 'Schema', params: {id: domain.id}}") {{ domain.name }}

</template>

<script lang="coffee">
_ = require 'lodash'
export default
  name: 'Domains'
  data: ->
    selected_domain: ''
    selected_subdomains: []
  methods:
    select_domain: (name) ->
      console.log "Selecting name!"
      console.log name
      console.log this
  computed:
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

  mounted: ->
    @$store.dispatch 'load_db'
</script>
