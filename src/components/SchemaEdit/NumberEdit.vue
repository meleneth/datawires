<template lang="pug">
div
  h1 NumberEdit
  h5 Path: '{{ path }}'
  h3 {{ title }}
  textarea(v-model="description" label="description")
  table
    tr
      td(v-if="!has_minimum")
        button(v-on:click="add_minimum") add minimum
      td(v-if="has_minimum")
        input(type="text" v-model="current.minimum" label="minimum")
        button(v-on:click="remove_minimum") remove minimum
      td(v-if="!has_maximum")
        button(v-on:click="add_maximum") add maximum
      td(v-if="has_maximum")
        input(type="text" v-model="current.maximum")
        button(v-on:click="remove_maximum") remove maximum
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'NumberEdit'
  props:
    schema: Object
    current: Object
    path: String
  data: ->
    title: ''
    description: ''
  mounted: ->
    @title = @current.title
    @description = @current.description
  computed:
    has_minimum: ->
      @current.hasOwnProperty 'minimum'
    has_maximum: ->
      @current.hasOwnProperty 'maximum'
  watch:
    description: ->
      @save_changes()
  methods:
    add_minimum: ->
      @current['minimum'] = 0
      @save_changes()
    remove_minimum: ->
      delete @current.minimum
      @save_changes()
    add_maximum: ->
      @current['maximum'] = 0
      @save_changes()
    remove_maximum: ->
      delete @current.maximum
      @save_changes()
    save_changes: ->
      @$emit 'updateNumber', {path: @path, description: @description}
</script>
