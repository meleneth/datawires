<template lang="pug">
  div
    h3 {{ field.title }}
    md-field(v-if="!has_enum")
      label {{ field.description }}
      md-input(v-model="field_value")
    md-field(v-if="has_enum")
      label(for="field_value") {{ field.description }}
      md-select(v-model="field_value" name="value" id="value")
        md-option(v-for="item, index in field.property.enum" :value="item" :key="index") {{ item }}
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentStringEdit'
  props:
    field: Object
  data: ->
    field_value: 0
  mounted: ->
    @field_value = @field.current
  computed:
    has_enum: ->
      return @field.property.hasOwnProperty 'enum'
</script>
