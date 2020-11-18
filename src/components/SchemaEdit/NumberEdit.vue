<template lang="pug">
  div
    h1 NumberEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
    v-textarea(v-model="description" label="description")
    v-container
      v-row
        v-col(v-if="!has_minimum")
          v-btn(v-on:click="add_minimum") add minimum
        v-col(v-if="has_minimum")
          v-text-field(v-model="current.minimum" label="minimum")
          v-btn(v-on:click="remove_minimum") remove minimum
        v-col(v-if="!has_maximum")
          v-btn(v-on:click="add_maximum") add maximum
        v-col(v-if="has_maximum")
          v-text-field(v-model="current.maximum")
          v-btn(v-on:click="remove_maximum") remove maximum
</template>

<script lang="coffee">
import Vue from 'vue'
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
      Vue.set @current, 'minimum', 0
      @save_changes()
    remove_minimum: ->
      delete @current.minimum
      @save_changes()
    add_maximum: ->
      Vue.set @current, 'maximum', 0
      @save_changes()
    remove_maximum: ->
      delete @current.maximum
      @save_changes()
    save_changes: ->
      @$emit 'updateNumber', {path: @path, description: @description}
</script>
