class SchemaWrapper
  constructor: (@schema) ->

make_schema = (domain, name, description) ->
  new_schema =
    "$id": "http://#{domain}/#{name}.json"
    "$defs": {}
    type: "object"
    properties: {}
    title: "The #{domain} #{ name } Schema"
    description: description
  return new SchemaWrapper new_schema

export { make_schema, SchemaWrapper }
