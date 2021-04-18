<template lang="pug">
div
  h1 Import
  br
  router-link(:to="'/document/' + id + '/edit'") edit
  br
  pre {{ doc }}
</template>

<script lang="coffee">
export default 
  name: 'Import'
  data: ->
    doc: false
  props:
    id: String
  mounted: ->
    @$store.dispatch 'get_doc', @id
      .then (d) =>
        @doc = d
</script>
