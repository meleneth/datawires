<template lang="pug">
v-sheet
  data-view(:field="f" v-for="f in field.children")
</template><script lang="coffee">
import Vue from 'vue'

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataSheet'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
