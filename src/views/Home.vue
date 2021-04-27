<template lang="pug">
hello-world
div(class="bg-white rounded-xl p-8 md:p-0")
  div(class="bg-grey rounded-xl p-8 md:p-0")
    p hi
</template>

<script>
  import HelloWorld from '../components/HelloWorld'

  export default {
    name: 'Home',

    components: {
      HelloWorld,
    },
  }
</script>
