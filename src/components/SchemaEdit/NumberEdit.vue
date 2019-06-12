<template lang="pug">
  div
    h1 NumberEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
    md-field
      label description
      md-textarea(v-model="description")
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'NumberEdit'
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
      @$emit 'updateNumber', {path: @path, description: @description}
</script>
