<template lang="pug">
h3(:style="field.style", :class="field.classes")
  data-view(:field="f" v-for="f in field.children")
</template><script lang="coffee">
import Vue from 'vue'

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataH3'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
