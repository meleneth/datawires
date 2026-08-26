# frozen_string_literal: true

module Sources
  module Schema
    KEY = "datawires-source"
    TITLE = "Datawires Source"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "datawires:core/#{KEY}",
      "title" => TITLE,
      "type" => "object",
      "required" => %w[version title adapter config],
      "properties" => {
        "version" => { "const" => 1 },
        "title" => { "type" => "string", "minLength" => 1 },
        "adapter" => { "type" => "string", "minLength" => 1 },
        "config" => { "type" => "object" },
        "schedule" => { "type" => "object" },
        "observation" => { "type" => "object" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
