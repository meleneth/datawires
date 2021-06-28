import { expect } from 'chai'

import { make_schema } from '@/lib/datawires'

describe 'lib/datawires', =>
  describe '#make_schema', =>
    it 'returns a schema wrapper', =>
      wrapper = make_schema 'demo.sec7or.com', 'test', 'test the schema generator'
      expect(wrapper.schema.$id).to.eql 'http://demo.sec7or.com/test.json'

