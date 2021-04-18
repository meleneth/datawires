<template lang="pug">
v-col
  data-view(:field="f" v-for="f in field.children")
</template><script lang="coffee">
import Vue from 'vue'

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataCol'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
