import { expect } from 'chai'

import { Builder, FormBuilder } from '@/components/DataView/builder'

describe "FormBuilder", =>
  it "works for simple case", =>
    builder = new FormBuilder 'container'
    expect(builder.data).to.eql
      type: 'form'
      style: {}
      classes: {}
      children: []
  describe "#add_input", =>
    it "works for simple case", =>
      builder = new FormBuilder 'container'
      input = builder.add_input {target: 'me'}, 'target'
      input.set_id "some-some-id"
      expect(builder.data).to.eql
        type: 'form'
        style: {}
        classes: {}
        children: [
          {
            "children": []
            "classes": {}
            "field": "target"
            "style": {}
            "id": "some-some-id"
            "target": {
              "target": "me"
            }
            "type": "input"
            "input_type": "text"
          }
        ]

    it "does not include label", =>
      builder = new FormBuilder 'container'
      input = builder.add_input {target: 'me'}, 'target'
      input.set_id "some-id"

      expect(builder.data).to.eql
        type: 'form'
        style: {}
        classes: {}
        children: [
          {
            "children": []
            "classes": {}
            "field": "target"
            "style": {}
            "target": {
              "target": "me"
            }
            "type": "input"
            "input_type": "text"
            "id": "some-id"
          }
        ]


