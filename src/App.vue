<template lang="pug">
  div(dark)
    div(app color="primary" dark)
      .d-flex.align-center
        h1 |)atawires
    div(dark)
      div
        div
          div
            router-link(to="/") Home
          div
            router-link(to="/domains") Domains
          div
            router-link(to="/dataviewdemo") DataViewDemo
          div
            router-link(to="/import") Import
          div
            router-link(to="/admin") Admin
          div
            router-link(to="/about") About
      router-view
</template>

<script lang="coffee">
export default
  name: 'App',
  mounted: ->
    @$store.dispatch 'load_db'
</script>
