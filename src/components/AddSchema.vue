<template lang="pug">
table
  tr
    td(colspan="2")
      button(v-on:click="createNewSchema") create
  tr
    td(colspan="2")
      h2 {{ fullschemaname }}
  tr
    td
      .label domain
      input(type="text" v-model="new_schema_domain" label="New Schema Domain")
    td
      .label schema
      input(type="text" v-model="new_schema_name" label="New Schema Name")
  tr
    td(colspan="2")
      .label Description
      input(type="text" v-model="new_schema_description" label="Description")
</template>
<script lang="coffee">
pointer = require 'json-pointer'
import { make_schema } from "@/lib/datawires"

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
      new_schema = make_schema @new_schema_domain, @new_schema_name, @new_schema_description
      @$store.dispatch 'add_entry', new_schema.schema
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
