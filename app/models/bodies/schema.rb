# frozen_string_literal: true

module Bodies
  module Schema
    KEY = "body"
    TITLE = "Body"

    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => TITLE,
      "type" => "object",
      "required" => %w[name],
      "properties" => {
        "name" => { "type" => "string", "minLength" => 1 },
        "description" => { "type" => "string" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
