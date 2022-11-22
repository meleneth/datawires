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
  p: false
  button: false

DataView =
  name: 'DataView'
  components:
    "data-view": false
    "data-container": false
  props:
    field: Object
  beforeCreate: ->
    @$options.components['data-button'] = require('./DataButton.vue').default
    @$options.components['data-card'] = require('./DataCard.vue').default
    @$options.components['data-col'] = require('./DataCol.vue').default
    @$options.components['data-container'] = require('./DataContainer.vue').default
    @$options.components['data-div'] = require('./DataDiv.vue').default
    @$options.components['data-form'] = require('./DataForm.vue').default
    @$options.components['data-grid'] = require('./DataGrid.vue').default
    @$options.components['data-h3'] = require('./DataH3.vue').default
    @$options.components['data-label'] = require('./DataLabel.vue').default
    @$options.components['data-p'] = require('./DataP.vue').default
    @$options.components['data-row'] = require('./DataRow.vue').default
    @$options.components['data-sheet'] = require('./DataSheet.vue').default
    @$options.components['data-text-area'] = require('./DataTextArea.vue').default
    tlookup['button'] = @$options.components['data-button']
    tlookup['card'] = @$options.components['data-card']
    tlookup['col'] = @$options.components['data-col']
    tlookup['container'] = @$options.components['data-container']
    tlookup['div'] = @$options.components['data-div']
    tlookup['form'] = @$options.components['data-form']
    tlookup['h3'] = @$options.components['data-h3']
    tlookup['label'] = @$options.components['data-label']
    tlookup['p'] = @$options.components['data-p']
    tlookup['row'] = @$options.components['data-row']
    tlookup['sheet'] = @$options.components['data-sheet']
    tlookup['textarea'] = @$options.components['data-text-area']
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
