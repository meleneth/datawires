<template lang="pug">
  div
    h1 NumberEdit
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
    .md-layout(v-for="property in myproperties")
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
  name: 'NumberEdit'
  props:
    schema: Object
  data: ->
    new_property_type: ''
    new_property_name: ''
    path: ''
  mounted: ->
    @path = @$route.query.path
    console.log "path of #{@path} set"
  computed:
    myproperties: ->
      if @path == "/" then p = "/properties" else p = @path
      console.log p
      console.log @schema
      console.log "And yet"
      if @path and @schema._id
        pointer.get @schema, p
  methods:
    add_property: ->
      console.log "(ObjectEdit)Adding property"
</script>
