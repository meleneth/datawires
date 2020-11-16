import { expect } from 'chai'
import { shallowMount } from '@vue/test-utils'
import DocumentEditString from '@/components/DocumentEdit/StringEdit.vue'

describe 'DocumentEdit/StringEdit.vue', =>
  it 'brace syntax is reasonable', =>
    foo = 'bar'
    thing = { foo }

    expect(thing.foo).to.include "bar"

  it 'shows title', =>
    msg = 'new message'
    object =
      name: "value"
      description: "Give me a value"
    title =  "a name with a value"
    path = "/name"
    current = 'foo'
    property =
      "enum": ['foo', 'bar', 'baz']
    wrapper = shallowMount DocumentEditString,
      propsData:
        field: { current, title, path, property}
      stubs:
        "md-input": {template: "<input />"}
        "md-field": {template: "<p />"}
    expect(wrapper.text()).to.include("a name with a value")
