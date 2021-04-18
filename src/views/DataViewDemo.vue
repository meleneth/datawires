<template lang="pug">
div
  p Builder and DataView Demo
  div(v-for="view in views")
    data-view(:field="view")
    hr
    hr
</template><script lang="coffee">
import Vue from 'vue'
import Builder from '@/components/DataView/builder.coffee'
import DataView from '@/components/DataView/DataView.vue'

export default 
  name: 'DataViewDemo'
  data: ->
    views: []
  components:
    'data-view': DataView
  mounted: ->
    builder = new Builder('container')
    builder.add_text 'Some Story about Some Thing'
    Vue.set @views, 0, builder.data
    builder = new Builder('container')
    row = builder.add_row()
    row.add_col()
    row.add_col().add_card().add_p().add_text 'Some Story about Some Thing'
    row.add_col()
    Vue.set @views, 1, builder.data
    builder = new Builder('container')
    row = builder.add_row()
    row.add_col().add_p().add_text 'Some Story about Some Thing'
    row.add_col().add_p().add_text 'Some Story about Some Thing'
    Vue.set @views, 2, builder.data
    builder = new Builder('container')
    row = builder.add_row()
    row.add_col().add_sheet().add_p().add_text 'Some Story about Some Thing'
    row.add_col()
    row.add_col().add_button 'Some Text', 'nothing'
    row.add_col()
    row.add_col().add_card().add_p().add_text 'Some Story about Some Thing'
    Vue.set @views, 3, builder.data
</script>
