<template lang="pug">
  div
    h1 ArrayEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
    v-textarea(v-model="description" label="description")
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'ArrayEdit'
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
      @$emit 'updateArray', {path: @path, description: @description}
</script>
