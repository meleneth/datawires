<template lang="pug">
textarea(:style="field.style", :class="field.classes" :id="field.id" v-model="field.target[field.field]")
</template><script lang="coffee">
import Vue from 'vue'

import DataView from '@/components/DataView/DataView.vue'

export default
  name: 'DataTextArea'
  props:
    field: Object
  components:
    'data-view': DataView
</script>
