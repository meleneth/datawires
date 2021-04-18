<template lang="pug">
div
  h1 ObjectEdit
  h5 Path: '{{ path }}'
  h3 {{ title }}
  v-container
    v-row
      v-col
        v-select(:items="item_types" v-model="new_property_type" label="Type")
      v-col
        v-text-field(v-model="new_property_name" label="New Property Name")
      v-col
        v-btn(v-on:click="add_property") Create
  v-container(v-for="property in myproperties")
    v-row
      v-col
        | {{ property.type }}
      v-col
        schema-edit-link(:to="path + '/properties/' + property.title" :label="property.title")
      v-col
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
    item_types: ['string', 'number', 'object', 'array']
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
      new_prop = {title: @new_property_name, description: '', type: @new_property_type}
      if @new_property_type == 'object'
        new_prop['properties'] = {}
      target = pointer.get @schema, "#{@path}/properties"
      @emit 'addProperty', {path: "#{@path}/properties", prop: new_prop, title: @new_property_name}
      EventBus.emit('navigate', {path: "#{@path}/properties/#{@new_property_name}"})
      @new_property_name = ''
    save_changes: ->
      @emit 'updateObject', {path: @path, description: @description}
</script>
