# frozen_string_literal: true

module ProceduralPolicies
  module Schema
    KEY = "procedural-policy"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => "Procedural Policy",
      "type" => "object",
      "required" => %w[version name role_capabilities commands],
      "properties" => {
        "version" => { "const" => 1 },
        "name" => { "type" => "string", "minLength" => 1 },
        "role_capabilities" => {
          "type" => "object",
          "additionalProperties" => {
            "type" => "array",
            "items" => { "type" => "string", "minLength" => 1 },
            "minItems" => 1,
            "uniqueItems" => true
          }
        },
        "commands" => { "type" => "object" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
