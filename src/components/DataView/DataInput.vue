<template lang="pug">
input(:class="field.classes", :id="field.id" v-model="field.target[field.field]" :type="field.input_type")
</template><script lang="coffee">
import Vue from 'vue'

DataInput =
  name: 'DataInput'
  props:
    field: Object
export default DataInput

</script>
