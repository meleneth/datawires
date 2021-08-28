<template lang="pug">
div
  h1 StringEdit
  h5 Path: '{{ path }}'
  h3 {{ title }}
  v-textarea(v-model="description" label="description")
  h3 Allowed Values
  table
    tr
      td
        ul(v-if="current.enum")
          li(v-for="item in current.enum") {{ item }}
      td
        input(type="text" v-model="allowed_value_to_add")
      td
        button(v-on:click="add_enum_item") add
</template>
<script lang="coffee">
pointer = require 'json-pointer'
import Vue from 'vue'
export default 
  name: 'StringEdit'
  props:
    schema: Object
    current: Object
    path: String
  data: ->
    title: ''
    description: ''
    allowed_value_to_add: ''
  mounted: ->
    @title = @current.title
    @description = @current.description
  watch:
    description: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, description: @description}
    add_enum_item: ->
      if not @current.hasOwnProperty('enum')
        Vue.set @current, 'enum', []
      @current.enum.push @allowed_value_to_add
      @allowed_value_to_add = ''
      @save_changes()
</script>
