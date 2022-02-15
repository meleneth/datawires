import { expect } from 'chai'

import { make_schema } from '@/lib/datawires'

describe 'lib/datawires', =>
  describe '#make_schema', =>
    it 'returns a schema wrapper', =>
      wrapper = make_schema 'demo.sec7or.com', 'test', 'test the schema generator'
      expect(wrapper.schema.$id).to.eql 'http://demo.sec7or.com/test.json'
      expect(wrapper.schema.$schema).to.eql 'https://json-schema.org/draft/2020-12/schema'
      expect(wrapper.schema.$defs).to.eql {}
      expect(wrapper.schema.type).to.eql 'object'
      expect(wrapper.schema.properties).to.eql {}
      expect(wrapper.schema.title).to.eql 'The demo.sec7or.com test Schema'
      expect(wrapper.schema.description).to.eql 'test the schema generator'
  describe "#add_property", =>
    it 'adds a simple object property by default', =>
      wrapper = make_schema 'demo.sec7or.com', 'test', 'test the schema generator'
      wrapper.add_property 'details'

      expect(wrapper.schema.properties.details.type).to.eql 'object'
      expect(wrapper.schema.properties.details.title).to.eql 'details'
      expect(wrapper.schema.properties.details.description).to.eql 'The details property'
    it 'adds a simple string object', =>
      wrapper = make_schema 'demo.sec7or.com', 'test', 'test the schema generator'
      wrapper.add_property 'name', 'string'

      expect(wrapper.schema.properties.name.type).to.eql 'string'
      expect(wrapper.schema.properties.name.title).to.eql 'name'
      expect(wrapper.schema.properties.name.description).to.eql 'The name property'



