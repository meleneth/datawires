import { expect } from 'chai'

describe 'Reality', =>
  it 'brace syntax is reasonable', =>
    foo = 'bar'
    thing = { foo }

    expect(thing.foo).to.include "bar"

