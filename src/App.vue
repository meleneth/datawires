<template lang="pug">
  v-app(dark)
    v-app-bar(app color="primary" dark)
      .d-flex.align-center
        h1 |)atawires
    v-main(dark)
      v-container
        v-row
          v-col
            router-link(to="/") Home
          v-col
            router-link(to="/domains") Domains
          v-col
            router-link(to="/dataviewdemo") DataViewDemo
          v-col
            router-link(to="/import") Import
          v-col
            router-link(to="/admin") Admin
          v-col
            router-link(to="/about") About
      router-view
</template>

<script lang="coffee">
export default
  name: 'App',
  mounted: ->
    @$store.dispatch 'load_db'
</script>
