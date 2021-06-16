<template lang="pug">
div(class="sm:rounded-lg" :style="gridstyle")
  data-view(:field="f" v-for="f in field.children")
</template>
<script lang="coffee">
import Vue from 'vue'

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataGrid'
  props:
    field: Object
  computed:
    gridstyle: ->
      if @field and @field.style
        return @field.style
      return {}
  components:
    'data-view': DataView
</script>
