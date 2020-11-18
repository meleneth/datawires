<template lang="pug">
  v-text-field(v-model="value" type="number" :label="field.title")
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentGridNumberEdit'
  props:
    current: Number
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
      @$emit 'updateNumber', {path: @path, value: @value, doc: @doc}
</script>
