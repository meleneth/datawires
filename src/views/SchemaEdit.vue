<template lang="pug">
  div
    h3 {{ schema.$schema }}
    .md-layout
      .md-layout-item.md-size-33
        div(id="diffdiv" style="text-align: left")
      .md-layout-item.md-size-66
        md-button.md-primary.md-raised(v-on:click="save_schema") save
        md-card
          schema-edit-link(:to="''" label="Top")
          component(:is="selectedComponent"
                    :current="current"
                    :schema="schema"
                    :path="path"
                    v-on:addProperty="add_property"
                    v-on:updateString="update_string"
                    v-on:updateArray="update_array"
                    v-on:updateNumber="update_number"
                    v-on:updateObject="update_object"
                    v-if="selectedComponent")
</template>

<script lang="coffee">
import EventBus from '@/components/SchemaEdit/EventBus'
import SchemaEditLink from '@/components/SchemaEdit/SchemaEditLink.vue'
import ObjectEdit from '@/components/SchemaEdit/ObjectEdit.vue'
import StringEdit from '@/components/SchemaEdit/StringEdit.vue'
import ArrayEdit from '@/components/SchemaEdit/ArrayEdit.vue'
import NumberEdit from '@/components/SchemaEdit/NumberEdit.vue'

pointer = require 'json-pointer'
difflib = require 'jsdifflib'

contextSize = null

tlookup = {'object': ObjectEdit, 'array': ArrayEdit, 'string': StringEdit, 'number': NumberEdit}

export default 
  name: 'SchemaEdit'
  components:
    'schema-edit-link': SchemaEditLink
  props:
    id: String
  data: ->
    schema: {}
    path: ''
    selectedComponent: false
    current: {}
    renderedJson: ''
    sourceRenderedJson: ''
  created: ->
    EventBus.$on 'navigate', (data) =>
      @path = data.path
      @current = pointer.get @schema, @path
      @selectedComponent = tlookup[@current.type]
  mounted: ->
    @load_schema()
  methods:
    add_property: (data) ->
      target = pointer.get @schema, data.path
      target[data.title] = data.prop
      @update_rendered_json()
    update_string: (data) ->
      target = pointer.get @schema, data.path
      target.description = data.description
      @update_rendered_json()
    update_number: (data) ->
      target = pointer.get @schema, data.path
      target.description = data.description
      @update_rendered_json()
    update_array: (data) ->
      target = pointer.get @schema, data.path
      target.description = data.description
      @update_rendered_json()
    update_object: (data) ->
      target = pointer.get @schema, data.path
      target.description = data.description
      @update_rendered_json()
    update_rendered_json: ->
      @renderedJson = JSON.stringify @schema, null, 2
      base = difflib.stringAsLines @sourceRenderedJson
      newtxt = difflib.stringAsLines @renderedJson
      sm = new difflib.SequenceMatcher base, newtxt
      opcodes = sm.get_opcodes()
      mydiv = document.getElementById 'diffdiv'
      while mydiv.firstChild
        mydiv.removeChild mydiv.firstChild
      contextSize = contextSize ? contextSize : null
      mydiv.appendChild difflib.buildView
        baseTextLines: base
        newTextLines: newtxt
        opcodes: opcodes
        baseTextName: "base schema"
        newTextName: "new schema"
        contextSize: contextSize
        inline: true
    save_schema: ->
      console.log "Saving so easy? lets see you do it.."
      @$store.dispatch "save_entry", @schema
        .then (result) ->
          console.log "I've been away"
          console.log result
    load_schema: ->
      console.log "Fetching #{@id}"
      @$store.dispatch 'get', @id
        .then (schema) =>
          @schema = schema
          @current = pointer.get @schema, @path
          @sourceRenderedJson = JSON.stringify @schema, null, 2
          @selectedComponent = tlookup[@current.type]
          @update_rendered_json()
</script>
<style>
table.diff {
	border-collapse:collapse;
	border:1px solid darkgray;
	white-space:pre-wrap
}
table.diff tbody {
	font-family:Courier, monospace
}
table.diff tbody th {
	font-family:verdana,arial,'Bitstream Vera Sans',helvetica,sans-serif;
	background:#EED;
	font-size:11px;
	font-weight:normal;
	border:1px solid #BBC;
	color:#886;
	padding:.3em .5em .1em 2em;
	text-align:right;
	vertical-align:top
}
table.diff thead {
	border-bottom:1px solid #BBC;
	background:#EFEFEF;
	font-family:Verdana
}
table.diff thead th.texttitle {
	text-align:left
}
table.diff tbody td {
	padding:0px .4em;
	padding-top:.4em;
	vertical-align:top;
}
table.diff .empty {
	background-color:#DDD;
}
table.diff .replace {
	background-color:#FD8
}
table.diff .delete {
	background-color:#E99;
}
table.diff .skip {
	background-color:#EFEFEF;
	border:1px solid #AAA;
	border-right:1px solid #BBC;
}
table.diff .insert {
	background-color:#9E9
}
table.diff th.author {
	text-align:right;
	border-top:1px solid #BBC;
	background:#EFEFEF
}
</style>

