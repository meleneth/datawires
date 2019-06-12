<template lang="pug">
  div
    h1 StringEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
    md-field
      label description
      md-textarea(v-model="description")
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
  mounted: ->
    @title = @current.title
    @description = @current.description
  watch:
    description: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, description: @description}
</script>
