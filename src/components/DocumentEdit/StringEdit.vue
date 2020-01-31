<template lang="pug">
  div
    h3 {{ title }}
    md-field
      label {{ description }}
      md-input(v-model="value")
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentStringEdit'
  props:
    current: String
    path: String
    title: String
    description: String
  data: ->
    value: undefined
  mounted: ->
    @value = @current
  watch:
    value: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, value: @value}
</script>
