<template lang="pug">
div
  v-container
    v-row.text-center
      v-col(cols="12")
        v-img(class="my-3"
          :src="require('../assets/logo.svg')"
          contain
          height="200"
        )
    v-row
      v-col(cols="12")
        | {{ msg }}

      v-col(class="mb-4")
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
