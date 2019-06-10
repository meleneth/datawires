<template lang="pug">
  div
    h1 StringEdit
    h5 Path: '{{ path }}'
    .md-layout
      .md-layout-item.md-size-66
        md-field
          label title
          md-input(v-model="title")
        md-field
          label description
          md-textarea(v-model="description")
      .md-layout-item.md-size-33
      .md-layout-item
        md-button.md-raised.md-primary(v-on:click="save_changes") ok
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'StringEdit'
  props:
    schema: Object
  data: ->
    path: @$route.query.path
    title: ''
    description: ''
  beforeRouteUpdate: (to, from, next) ->
    @path = to.query.path
    @title = pointer.get @schema, "#{path}/title"
    @description = pointer.get @schema, "#{path}/description"
  watch:
    schema: ->
      if @schema._id
        @title = pointer.get @schema, "#{@path}/title"
        @description = pointer.get @schema, "#{@path}/description"
  methods:
    save_changes: ->
      @$emit 'updateString', {path: @path, title: @title, description: @description}
</script>
