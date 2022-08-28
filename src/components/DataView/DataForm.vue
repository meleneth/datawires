<template lang="pug">
form(:style="field.style" :class="field.classes")
  data-view(:field="f" v-for="f in field.children")
p Brought to you by Carl's Jr.
</template><script lang="coffee">

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataContainer'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
