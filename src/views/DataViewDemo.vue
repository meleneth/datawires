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
    builder.add_row().add_col().add_p 'Some Story about Some Thing'
    Vue.set @views, 1, builder.data
</script>
