<template lang="pug">
div
  table
    tr.text-center
      td(cols="12")
        img(class="my-3"
          :src="require('../assets/logo.svg')"
          contain
          height="200"
        )
    tr
      td(cols="12")
        | {{ msg }}

      td(class="mb-4")
        h1(class="display-2 font-weight-bold mb-3")
          | Welcome to |)atawires
        p(class="subheading font-weight-regular")
          | Dealing with Data so you don't have to
</template>

<script lang="coffee">
  export default
    name: 'HelloWorld'
    props:
      msg: String
</script>
