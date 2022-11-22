<template lang="pug">
label(:style="field.style", :class="field.classes" :for="field.for", :name="field.name", :id="field.id")
  | {{ field.text }}
</template><script lang="coffee">
export default
  name: 'DataLabel'
  props:
    field: Object
</script>
