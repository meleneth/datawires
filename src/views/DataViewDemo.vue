<template lang="pug">
div
  p Builder and DataView Demo
  div(v-for="view in views")
    data-view(:field="view")
    hr
    hr
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
    lorem_paragraph = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis quam neque, consequat eu metus eget, sodales maximus diam. Sed efficitur ipsum sit amet nisl aliquam tincidunt. Nunc nec ultrices magna. Ut dapibus augue sed nunc bibendum, eu interdum velit euismod. Donec fermentum, dui ac rhoncus cursus, nunc nibh lacinia arcu, id molestie risus quam quis odio. Proin hendrerit, turpis non aliquam elementum, eros ipsum varius felis, consequat pretium magna ligula ac metus. Maecenas pellentesque in leo vitae ultricies. Etiam justo ex, porttitor nec lorem eget, consectetur elementum diam."
    builder = new Builder('container')
    builder.add_text lorem_paragraph
    @views[0] = builder.data
    builder = new Builder('container')
    row = builder.add_row()
    row.add_col()
    row.add_col().add_card().add_p().add_text lorem_paragraph
    row.add_col()
    @views[1] = builder.data
    builder = new Builder('container')
    row = builder.add_row()
    row.add_col().add_p().add_text lorem_paragraph
    row.add_col().add_p().add_text lorem_paragraph
    @views[2] = builder.data
    builder = new Builder('container')
    row = builder.add_row()
    row.add_col().add_sheet().add_p().add_text lorem_paragraph
    row.add_col()
    row.add_col().add_button 'Some Text', 'nothing'
    row.add_col()
    row.add_col().add_card().add_p().add_text lorem_paragraph
    @views[3] = builder.data
</script>
