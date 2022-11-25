<template lang="pug">
button(:class="field.classes" @click="field.target") {{ field.label }}
</template><script lang="coffee">
import Vue from 'vue'

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataButton'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
