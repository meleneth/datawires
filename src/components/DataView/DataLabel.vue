<template lang="pug">
label(:style="field.style", :class="field.classes" :for="field.for") spome text to edit
</template><script lang="coffee">

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataLabel'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
