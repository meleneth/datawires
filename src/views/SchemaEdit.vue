<template lang="pug">
  div

    h3 {{ schema.dw$schema }}
    .md-layout
      .md-layout-item.md-size-33
        pre(style="text-align: left")
          | {{ renderedJson }}
      .md-layout-item.md-size-66
        router-link(:to="{name: 'ObjectEdit', params: {id: schema._id}, query: {path: ''}}") Top
        router-view(:schema="schema" v-on:addProperty="add_property")
</template>

<script lang="coffee">
pointer = require 'json-pointer'

export default 
  name: 'SchemaEdit'
  props:
    id: String
  data: ->
    schema: {}
    path: ''
    renderedJson: ''
  mounted: ->
    @path = @$route.query.path
    @load_schema()
  methods:
    add_property: (data) ->
      target = pointer.get @schema, data.path
      target[data.title] = data.prop
      @update_rendered_json()
    update_rendered_json: ->
      @renderedJson = JSON.stringify @schema, null, 2
    load_schema: ->
      console.log "Fetching #{@id}"
      @$store.dispatch 'get', @id
        .then (schema) =>
          @schema = schema
          @update_rendered_json()
</script>
