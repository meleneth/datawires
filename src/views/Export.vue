<template lang="pug">
div
  h1 Export - {{ domain }}
  table
    tr
      td
      td
        pre {{ string_export }}
      td
</template>
<script lang="coffee">
import map_task from '@/lib/map_task'

export default 
  name: 'Export'
  props:
    domain: String
  data: ->
    schemas: []
    documents: []
  computed: {
    string_export: ->
      data =
        "$ref": "http://export.datawires.sec7or.com"
        domains: [@domain]
        schemas: @schemas
        documents: @documents
      return data
    }
  mounted: ->
    @$store.dispatch 'set_page_title', "Export"
    @$store.dispatch 'getSchemasByDomain', @domain
      .then (schemas) =>
        @schemas = schemas
        make_request = (item) =>
          @$store.dispatch 'getDocumentsByRef', item.$id
            .then (documents) =>
              for doc in documents
                @documents.push doc
        process_response = (uri, response) =>
          _.map response.rows, (r) => @documents.push r.doc
        when_done = () =>
          console.log "DoneDone!"
        map_task [...schemas], make_request, process_response, when_done
</script>
