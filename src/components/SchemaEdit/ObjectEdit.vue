<template lang="pug">
  div
    h1 ObjectEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
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
        schema-edit-link(:to="path + '/properties/' + property.title" :label="property.title")
      .md-layout-item
        | {{ property.description }}
</template>

<script lang="coffee">
pointer = require 'json-pointer'

import EventBus from '@/components/SchemaEdit/EventBus'
import SchemaEditLink from '@/components/SchemaEdit/SchemaEditLink.vue'

export default 
  name: 'ObjectEdit'
  components:
    'schema-edit-link': SchemaEditLink
  props:
    schema: Object
    current: Object
    path: String
  data: ->
    new_property_type: ''
    new_property_name: ''
    lookUp: {string: 'StringEdit', object: 'ObjectEdit', array: 'ArrayEdit', number: 'NumberEdit'}
    title: ''
    description: ''
  watch:
    description: ->
      @save_changes()
  mounted: ->
    @title = @current.title
    @description = @current.description
  computed:
    myproperties: ->
      return pointer.get @schema, "#{@path}/properties"

  methods:
    add_property: ->
      new_prop = {title: @new_property_name, description: '', properties: {}, type: @new_property_type}
      target = pointer.get @schema, "#{@path}/properties"
      @$emit 'addProperty', {path: "#{@path}/properties", prop: new_prop, title: @new_property_name}
      EventBus.$emit('navigate', {path: "#{@path}/properties/#{@new_property_name}"})
      @new_property_name = ''
    save_changes: ->
      @$emit 'updateObject', {path: @path, description: @description}
</script>
