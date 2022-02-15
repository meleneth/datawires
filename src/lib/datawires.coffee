pointer = require 'json-pointer'

class SchemaWrapper
  constructor: (@schema) ->
  add_property: (property_name, property_type='object', property_description="NOTSET") ->
    if property_description == "NOTSET"
      property_description = "The #{property_name} property"
    new_property =
      type: property_type
      description: property_description
      title: property_name
    if property_type == 'object'
      new_property['properties'] = {}
    @schema.properties[property_name] = new_property
    @

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
