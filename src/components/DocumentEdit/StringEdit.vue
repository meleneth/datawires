<template lang="pug">
div
  .label {{ field.property.title }}
  input(type="text" v-if="!has_enum" v-model="value" :label="title")
  select(v-if="has_enum" :items="field.property.enum" v-model="value" :label="title")
    option(v-for="item in field.property.enum" :value="item") {{ item }}
</template>
<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'DocumentStringEdit'
  props:
    field: Object
    title: String
  data: ->
    value: 0
  mounted: ->
    @value = @field.current
  watch:
    value: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @field.path, value: @value}
  computed:
    has_enum: ->
      return @field.property.hasOwnProperty 'enum'
</script>
