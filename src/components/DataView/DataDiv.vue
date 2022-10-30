<template lang="pug">
div(:style="field.style", :class="field.classes", :name="field.name", :id="field.id")
  data-view(:field="f" v-for="f in field.children")
</template><script lang="coffee">

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataContainer'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
