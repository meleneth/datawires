<template lang="pug">
label(:style="field.style", :class="field.classes" :for="field.for", :name="field.name", :id="field.id") spome text to edit
</template><script lang="coffee">

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataLabel'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
