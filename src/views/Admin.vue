<template lang="pug">
div
  h1 Admin
  md-button.md-primary.md-raised(v-on:click="create_views") create views
  div(v-if="views_created") created
</template>

<script lang="coffee">
export default 
  name: 'Admin'
  mounted: ->
    @$store.dispatch 'set_page_title', "Admin"
  data: ->
    return
      views_created: false
  methods:
    create_views: ->
      ddoc =
        _id: '_design/schemas'
        views:
          documents:
            map: """function (doc) { if(doc.$ref) {
                      matches = doc.$ref.match("http:\/\/([^/]*)\/([^#]*)#");
                      emit([matches[1], matches[2]],1);
                    }}"""
            reduce: "_count"
          schemas:
            map: """function (doc) { if(doc.$schema) {
                      matches = doc.$schema.match("http:\/\/([^/]*)\/([^#]*)#");
                      emit([matches[1], matches[2]],1);
                    } }"""
            reduce: "_count"
      @$store.dispatch "save_entry", ddoc
        .then () =>
          @views_created = true
</script>
