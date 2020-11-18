<template lang="pug">
  div
    v-text-field(v-if="!has_enum" v-model="value" :label="title")
    v-select(v-if="has_enum" :items="property.enum" v-model="value" :label="description")
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
    property: Object
  data: ->
    value: undefined
  mounted: ->
    @value = @current
  watch:
    value: ->
      @save_changes()
  computed:
    has_enum: ->
      return @property.hasOwnProperty 'enum'
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, value: @value, doc: @doc}
</script>
