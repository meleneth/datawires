pointer = require 'json-pointer'

doc = {foo: {bar: 'baz'}}

p = pointer.get doc, "/foo"
console.log p

p = pointer.get doc, "/foo/bar"
console.log p

