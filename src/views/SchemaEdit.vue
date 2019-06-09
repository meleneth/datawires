<template lang="pug">
  div
    h3 {{ schema.dw$schema }}
    .md-layout
      .md-layout-item.md-size-33
        pre(style="text-align: left")
          | {{ renderedJson }}
      .md-layout-item.md-size-66
        | Hmm
        h5 Path: '{{ path }}'
        .md-layout
          .md-layout-item
            md-field
              label(for="new_property_type") Type
              md-select(v-model="new_property_type" name="new_property_type" id="new_property_type")
                md-option(value="string") string
                md-option(value="object") object
                md-option(value="array") array
                md-option(value="number") number
          .md-layout-item
            md-field
              label New Property Name
              md-input(v-model="new_property_name")
          .md-layout-item
            md-button.md-raised.md-primary(v-on:click="add_property") Create
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
    new_property_type: ''
    new_property_name: ''
  mounted: ->
    @load_schema()
  methods:
    add_property: ->
      console.log "Adding property"
    load_schema: ->
      @$store.dispatch 'get', @id
        .then (schema) =>
          @schema = schema
          @properties = pointer.get @schema, "#{@path}properties"
  computed:
    renderedJson: ->
      JSON.stringify @schema, null, 2
</script>
