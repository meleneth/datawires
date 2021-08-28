import Vue from 'vue'

mutations =
  ADD_ENTRY: (state, entry) ->
    state.entries.push entry
  SET_ENTRIES: (state, entries) ->
    state.entries = entries
  SET_SCREEN_TITLE: (state, title) ->
    state.screen_title = title
  SET_ENTRY: (state, entry) ->
    for value, index in state.entries
      if value._id == entry._id
        state.entries[index] = entry
        return
    state.entries.push entry
  SET_LOADING: (state, loading) ->
    state.loading = loading
  SET_DBLOADED: (state, db_loaded) ->
    state.db_loaded = db_loaded
  SET_SAVING: (state, saving) ->
    state.saving = saving

export default mutations
