# frozen_string_literal: true

module ProjectAffordances
  module Schema
    KEY = "datawires-project-affordance"
    TITLE = "Datawires Project Affordance"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "datawires:core/#{KEY}",
      "title" => TITLE,
      "type" => "object",
      "required" => %w[version title groups],
      "properties" => {
        "version" => { "const" => 1 },
        "title" => { "type" => "string", "minLength" => 1 },
        "description" => { "type" => "string" },
        "groups" => { "type" => "array", "items" => { "type" => "object" } }
      },
      "additionalProperties" => false
    }.freeze
  end
end
