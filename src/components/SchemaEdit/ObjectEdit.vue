<template lang="pug">
  div
    h1 ObjectEdit
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
        router-link(:to="{name: lookUp[property.type], params: {id: schema._id}, query: {path: path + '/properties/' + property.title}}") {{ property.title }}
      .md-layout-item
        | {{ property.description }}
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'ObjectEdit'
  beforeRouteUpdate: (to, from, next) ->
    @path = to.query.path
#    @$forceUpdate()
    next()
  props:
    schema: Object
  data: ->
    new_property_type: ''
    new_property_name: ''
    path: ''
    lookUp: {string: 'StringEdit', object: 'ObjectEdit', array: 'ArrayEdit', number: 'NumberEdit'}
  mounted: ->
    @path = @$route.query.path
  computed:
    myproperties: ->
      if @schema._id
        p = "#{@path}/properties"
        return pointer.get @schema, p
      []
  methods:
    add_property: ->
      new_prop = {title: @new_property_name, description: '', properties: {}, type: @new_property_type}
      target = pointer.get @schema, "#{@path}/properties"
      @$emit 'addProperty', {path: "#{@path}/properties", prop: new_prop, title: @new_property_name}
      @$router.push {name: @lookUp[new_prop.type], params: {id: @schema._id}, query: {path: "#{@path}/properties/#{@new_property_name}"}}
      @new_property_name = ''
</script>
