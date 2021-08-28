<template lang="pug">
div
  .label {{ field.property.title }}
  input(type="text" v-if="!has_enum" v-model="field_value" :label="title")
  select(v-if="has_enum" :items="field.property.enum" v-model="field_value" :label="title")
    option(v-for="item in field.property.enum" :value="item") {{ item }}
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
    console.log "I'm an honest string editor"
    console.log "and I come by me field honest"
    console.log @field
    @field_value = @field.current
  computed:
    has_enum: ->
      return @field.property.hasOwnProperty 'enum'
</script>
