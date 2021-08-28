<template lang="pug">
table
  tr
    td
      input(v-model="new_schema_domain")
      label New Schema Domain
    td
      input(v-model="new_schema_name")
      label New Schema Name
  tr
    td
      label Description
      textarea(v-model="new_schema_description")
    td
      h2 {{ fullschemaname }}
      md-button.md-raised.md-primary(v-on:click="createNewSchema") create
hr
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
  data: ->
    return
      new_schema_domain: ''
      new_schema_name: ''
      new_schema_description: ''
  methods:
    navigate: (evt, domain) ->
      evt.preventDefault()
      EventBus.emit('selectRootDomain', {domain: domain})
    createNewSchema: ->
      console.log "ok I guess createNewSchema is a thing now"
      new_schema =
        "$schema": "http://#{@new_schema_domain}/#{@new_schema_name}#"
        definitions: {}
        type: "object"
        properties: {}
        title: "The #{ @new_schema_name } Schema"
        description: @new_schema_description
      @$store.dispatch 'post_entry', new_schema
        .then (d) ->
          console.log "I have returned from my journey, and I now have the accent of a cabin man."
          console.log d
          console.log "Saved schema document with id #{d.id}"
          console.log d.id
          # go {name: 'Schema', params: {id: d.id}}

  computed:
    fullschemaname: ->
      return "http://#{@new_schema_domain}/#{@new_schema_name}#"
    rootDomains: ->
      rootdomains = _.map @domains, (d) -> d.basedomain
      _.uniq rootdomains
</script>
