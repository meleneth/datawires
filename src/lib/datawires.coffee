class SchemaWrapper
  constructor: (@schema) ->

make_schema = (domain, name, description) ->
  new_schema =
    "$id": "http://#{domain}/#{name}.json"
    "$schema": "https://json-schema.org/draft/2020-12/schema"
    "$defs": {}
    type: "object"
    properties: {}
    title: "The #{domain} #{ name } Schema"
    description: description
  return new SchemaWrapper new_schema

export { make_schema, SchemaWrapper }
