<template lang="pug">
  div
    h3 {{ schema.dw$schema }}
    .md-layout
      .md-layout-item
        pre(style="text-align: left")
          | {{ renderedJson }}
      .md-layout-item
        | Hmm
        h5 Path: '{{ path }}'
        .md-layout(v-for="property in properties" v-if="properties")
          .md-layout-item
            | {{ property.type }}
          .md-layout-item
            | {{ property.title }}
          .md-layout-item
            | {{ property.description }}
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'SchemaEdit'
  props:
    id: String
  data: ->
    schema: false
    path: '/'
    properties: []
  mounted: ->
    @load_schema()
  methods:
    load_schema: ->
      @$store.dispatch 'get', @id
        .then (schema) =>
          @schema = schema
          @properties = pointer.get @schema, "#{@path}properties"
  computed:
    renderedJson: ->
      JSON.stringify @schema, null, 2
</script>
