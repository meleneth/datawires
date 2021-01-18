import Vue from 'vue'

getters =
  schemas: (state) ->
    return _.filter state.entries, (e) -> e.$schema
  documents_for_domain: (state, getters) ->
    console.log "bogart"
    (store, domain) =>
      console.log "Thats bogAN you swine #{domain}"
      console.log state
      console.log domain
      console.log @
      store.dispatch "getDocumentsByRef", domain

export default getters
