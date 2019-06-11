<template lang="pug">
  div
    h1 NumberEdit
    h5 Path: '{{ path }}'
    h3 {{ title }}
    md-field
      label description
      md-textarea(v-model="description")
</template>

<script lang="coffee">
pointer = require 'json-pointer'
export default 
  name: 'NumberEdit'
  props:
    schema: Object
    id: String
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
    description: ->
      @save_changes()
    title: ->
      @save_changes()
  methods:
    save_changes: ->
      @$emit 'updateNumber', {path: @path, description: @description}
</script>
