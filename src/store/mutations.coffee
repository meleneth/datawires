import Vue from 'vue'

mutations =
  ADD_ENTRY: (state, entry) ->
    state.entries.push entry
  SET_ENTRIES: (state, entries) ->
    Vue.set state, 'entries', entries
  SET_ENTRY: (state, entry) ->
    for value, index in state.entries
      if value._id == entry._id
        Vue.set state.entries, index, entry
        return
    state.entries.push entry
  SET_LOADING: (state, loading) ->
    Vue.set state, 'loading', loading
  SET_DBLOADED: (state, db_loaded) ->
    Vue.set state, 'db_loaded', db_loaded
  SET_SAVING: (state, saving) ->
    Vue.set state, 'saving', saving

export default mutations
