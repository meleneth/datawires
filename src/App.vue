<template lang="pug">
div(class="min-h-screen bg-grey-darkest")
  header(class="pb-24 bg-indigo-light")
    div(class="max-w-3xl mx-auto px-4 sm:px-6 lg:max-w-7xl lg:px-8")
      div(class="relative py-5 flex items-center justify-center lg:justify-between")
        p(class="sr-only") |)atawires
    div
      nav
        a(v-for="link in navLinks" :key="link.title" href="#" :class="[link.active ? 'text-white' : 'text-indigo', 'text-sm font-medium rounded-md bg-white bg-opacity-0 px-3 py-2 hover:bg-opacity-10']" :aria-current="link.active ? 'page' : 'false'")
    div(dark)
      nav
        router-link(to="/") Home
        router-link(to="/domains") Domains
        router-link(to="/dataviewdemo") DataViewDemo
        router-link(to="/import") Import
        router-link(to="/admin") Admin
        router-link(to="/about") About
    router-view
</template>

<script lang="coffee">
navLinks = [
  { title: 'Home', active: true },
  { title: 'Profile', active: false },
  { title: 'Resources', active: false },
  { title: 'Company Directory', active: false },
  { title: 'Openings', active: false },
]

export default
  name: 'App',
  mounted: ->
    @$store.dispatch 'load_db'
  data: ->
    return {
      navLinks
    }
</script>
