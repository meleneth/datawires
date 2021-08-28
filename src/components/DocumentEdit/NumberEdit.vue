<template lang="pug">
div
  .label {{ field.title }}
  input(v-model="value" type="number" :label="field.title")
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentNumberEdit'
  props:
    field: Object
  data: ->
    value: undefined
  mounted: ->
    @value = @field.current
  watch:
    value: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateNumber', {path: @field.path, value: @value}
</script>
