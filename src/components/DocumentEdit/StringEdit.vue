<template lang="pug">
  div
    h3 {{ field.title }}
    md-field(v-if="!field.property.enum")
      label {{ field.description }}
      md-input(v-model="value")
    md-field(v-if="field.property.enum")
      label(for="value") {{ field.description }}
      md-select(v-model="value" name="value" id="value")
        md-option(v-for="e in field.property.enum" :value="e") {{ e }}
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentStringEdit'
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
      @$emit 'updateString', {path: @field.path, value: @value}
</script>
