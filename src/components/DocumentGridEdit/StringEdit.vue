<template lang="pug">
  div
    md-field
      md-input(v-model="value")
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentGridStringEdit'
  props:
    current: String
    path: String
    title: String
    description: String
    doc: Object
  data: ->
    value: undefined
  mounted: ->
    @value = @current
  watch:
    value: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, value: @value, doc: @doc}
</script>
