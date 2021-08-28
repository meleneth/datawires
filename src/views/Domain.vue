<template lang="pug">
div Domain
</template>

<script lang="coffee">
export default
  name: 'Domain'
  mounted: ->
    @$store.dispatch 'set_page_title', "Domain"
</script>
