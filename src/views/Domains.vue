<template lang="pug">
  div
    | Domains
    ul
      li(v-for="domain in domains")
        router-link(:to="{name: 'Schema', params: {id: domain.id}}") {{ domain.name }}

</template>

<script lang="coffee">
export default
  name: 'Domains'
  computed:
    domains: ->
      domain_names = {}
      for domain in @$store.state.entries
        if domain.dw$schema
          domain_names[domain.dw$schema] = domain._id
      domain_stats = []
      for key, value of domain_names
        domain_stats.push {name: key, id: value}
      domain_stats

  mounted: ->
    @$store.dispatch 'load_db'
</script>
