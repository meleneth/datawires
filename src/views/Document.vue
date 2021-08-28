<template lang="pug">
div
  | Document FINALLY WHAT ITS ALL ABOUT
  br
  router-link(:to="'/document/' + id + '/edit'") edit
  br
  pre {{ doc }}
</template>

<script lang="coffee">
export default 
  name: 'Document'
  data: ->
    doc: false
  props:
    id: String
  mounted: ->
    @$store.dispatch 'set_page_title', "Document"
    @$store.dispatch 'get_doc', @id
      .then (d) =>
        @doc = d
</script>
