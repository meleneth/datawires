<template lang="pug">
.px-4.py-6(class='sm:px-0')
  .h-96.rounded-lg.border-4.border-dashed.border-gray-200
    h2 {{ fullschemaname }}
    data-view(:field="view")
</template>
<script lang="coffee">
pointer = require 'json-pointer'
import { make_schema } from "@/lib/datawires"
import DecoratedFormBuilder from '@/lib/decorated/form.coffee'
import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'AddSchema'
  data: ->
    return
      new_schema_domain: ''
      new_schema_name: ''
      new_schema_description: ''
      view: {}
  mounted: ->
    my_display_grid = new DecoratedFormBuilder
    my_display_grid.add_header_text "Add Schema", "Fill in information and hit create to make a new schema"
    line = my_display_grid.add_line_2()
    my_display_grid.add_input line[0], "Domain", @, 'new_schema_domain'
    my_display_grid.add_input line[1], "Name", @, 'new_schema_name'
    my_display_grid.add_input my_display_grid, "Description", @, 'new_schema_description'
    my_display_grid.add_action_button "create", @createNewSchema.bind @
    @view = my_display_grid.data
  methods:
    createNewSchema: ->
      console.log "ok I guess createNewSchema is a thing now"
      new_schema = make_schema @new_schema_domain, @new_schema_name, @new_schema_description
      @$store.dispatch 'add_entry', new_schema.schema
        .then (d) ->
          console.log "I have returned from my journey, and I now have the accent of a cabin man."
          console.log d
          console.log "Saved schema document with id #{d.id}"
          console.log d.id
          console.log "And now I should go, but I'm too stupid to route push"
          # go {name: 'Schema', params: {id: d.id}}
  components:
    'data-view': DataView
  computed:
    fullschemaname: ->
      return "http://#{@new_schema_domain}/#{@new_schema_name}#"
</script>
