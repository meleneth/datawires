<template lang="pug">
div
  v-text-field(v-if="!has_enum" v-model="field_value" :label="title")
  v-select(v-if="has_enum" :items="field.property.enum" v-model="field_value" :label="title")
</template><script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentStringEdit'
  props:
    field: Object
    title: String
  data: ->
    field_value: 0
  mounted: ->
    @field_value = @field.current
  computed:
    has_enum: ->
      return @field.property.hasOwnProperty 'enum'
</script>
