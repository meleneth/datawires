<template lang="pug">
v-container
  v-row
    v-col
      h2 {{ fullschemaname }}
  v-row
    v-col
      v-text-field(v-model="new_schema_domain" label="New Schema Domain")
    v-col
      v-text-field(v-model="new_schema_name" label="New Schema Name")
    v-col
      v-btn(v-on:click="createNewSchema") create
  v-row
    v-col
      v-text-field(v-model="new_schema_description" label="Description")
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
      @$store.dispatch 'add_entry', new_schema
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
