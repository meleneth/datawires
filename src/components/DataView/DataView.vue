<template lang="pug">
  component(:is="field_type" :field="field")
    data-view(:field="f.field" v-for="f in fields")
</template><script lang="coffee">
import Vue from 'vue'

import DataText from '@/components/DataView/DataText.vue'

tlookup =
  text: DataText
  container: false
  row: false
  col: false
  card: false
  sheet: false

DataView =
  name: 'DataView'
  components:
    "data-view": false
    "data-container": false
  props:
    field: Object
  beforeCreate: ->
    @$options.components['data-container'] = require('./DataContainer.vue').default
    @$options.components['data-row'] = require('./DataRow.vue').default
    @$options.components['data-col'] = require('./DataCol.vue').default
    @$options.components['data-card'] = require('./DataCard.vue').default
    @$options.components['data-sheet'] = require('./DataSheet.vue').default
    tlookup['container'] = @$options.components['data-container']
    tlookup['row'] = @$options.components['data-row']
    tlookup['col'] = @$options.components['data-col']
    tlookup['card'] = @$options.components['data-card']
    tlookup['sheet'] = @$options.components['data-sheet']
  computed:
    field_type: ->
      tlookup[@field.type]
    fields: ->
      if @field
        return @field.children
      return []

DataView.components['data-view'] = DataView

export default DataView
</script>
