import { expect } from 'chai'

import HelloWorld from '@/components/HelloWorld.vue'

import store from '@/store'
import mutations from '@/store/mutations'

describe 'store_mutations', =>
  describe 'SET_ENTRY', =>
    it 'sets an entry if none exists', =>
      state = {'entries': []}
      mutations['SET_ENTRY'](state, {"_id": 'some_id'})
      expect(state).to.deep.equal
        entries: [{"_id": "some_id"}]
