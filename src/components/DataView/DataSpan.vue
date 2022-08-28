<template lang="pug">
span(:style="field.style", :class="field.class") {{ field.text }}
</template>
<script lang="coffee">
export default
  name: 'DataSpan'
  props:
    field: Object
</script>
