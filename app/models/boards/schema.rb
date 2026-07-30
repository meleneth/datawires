# frozen_string_literal: true

module Boards
  module Schema
    KEY = "datawires-board"
    TITLE = "Datawires Board"

    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => TITLE,
      "type" => "object",
      "required" => %w[version title sections actions],
      "properties" => {
        "version" => { "const" => 1 },
        "title" => { "type" => "string", "minLength" => 1 },
        "description" => { "type" => "string" },
        "layout" => { "type" => "object" },
        "sections" => { "type" => "array", "items" => { "type" => "object" } },
        "actions" => { "type" => "array", "items" => { "type" => "object" } }
      },
      "additionalProperties" => false
    }.freeze
  end
end
