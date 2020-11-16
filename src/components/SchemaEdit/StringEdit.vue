<template lang="pug">
  div
    h1 StringEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
    md-field
      label description
      md-textarea(v-model="description")
    h3 Allowed Values
    .md-layout
      .md-layout-item
        ul(v-if="current.enum")
          li(v-for="item in current.enum") {{ item }}
      .md-layout-item
        md-field
          md-input(v-model="allowed_value_to_add")
      .md-layout-item
        md-button.md-primary.md-raised(v-on:click="add_enum_item") add
</template>
<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'StringEdit'
  props:
    schema: Object
    current: Object
    path: String
  data: ->
    title: ''
    description: ''
    allowed_value_to_add: ''
  mounted: ->
    @title = @current.title
    @description = @current.description
  watch:
    description: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, description: @description}
    add_enum_item: ->
      if not 'enum' in @current
        @current.enum = []
      @current.enum.push @allowed_value_to_add
      @allowed_value_to_add = ''
      @save_changes()
</script>
