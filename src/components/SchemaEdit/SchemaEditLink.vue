<template lang="pug">
  div
    a(@click="navigate($event)") {{ label }}
</template>

<script lang="coffee">
import EventBus from '@/components/SchemaEdit/EventBus'
pointer = require 'json-pointer'
export default 
  name: 'SchemaEditLink'
  props:
    to: { type: String, required: true }
    label: { type: String, required: true }
    id: String
  methods:
    navigate: (evt) ->
      evt.preventDefault()
      EventBus.$emit('navigate', {path: @to})
</script>
