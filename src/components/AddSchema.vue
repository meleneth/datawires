<template lang="pug">
  div
    .md-layout
      .md-layout-item
        md-field
          md-input(v-model="new_schema_domain")
          label New Schema Domain
        md-field
          md-input(v-model="new_schema_name")
          label New Schema Name
      .md-layout-item
        md-field
          label Description
          md-textarea(v-model="new_schema_description")
      .md-layout-item
        h2 {{ fullschemaname }}
        md-button.md-raised.md-primary(v-on:click="createNewSchema") create
    hr
</template>
<script lang="coffee">
pointer = require 'json-pointer'

export default 
  name: 'AddSchema'
  data: ->
    return
      new_schema_domain: ''
      new_schema_name: ''
      new_schema_description: ''
  methods:
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
          console.log "And now I should go, but I'm too stupid to route push"
          # go {name: 'Schema', params: {id: d.id}}
  computed:
    fullschemaname: ->
      return "http://#{@new_schema_domain}/#{@new_schema_name}#"
</script>
