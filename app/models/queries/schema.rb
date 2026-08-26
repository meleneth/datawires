# frozen_string_literal: true

module Queries
  module Schema
    KEY = "datawires-query"
    TITLE = "Datawires Query"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "datawires:core/#{KEY}",
      "title" => TITLE,
      "type" => "object",
      "required" => %w[version key title metric_key aggregate],
      "properties" => {
        "version" => { "const" => 1 },
        "key" => { "type" => "string" },
        "title" => { "type" => "string" },
        "description" => { "type" => "string" },
        "metric_key" => { "type" => "string" },
        "source_id" => { "type" => "string", "format" => "uuid" },
        "dimensions" => { "type" => "object", "additionalProperties" => { "type" => "string" } },
        "window_seconds" => { "type" => "integer", "minimum" => 1 },
        "bucket_seconds" => { "type" => "integer", "minimum" => 1 },
        "aggregate" => { "enum" => %w[count sum min max average last] }
      },
      "additionalProperties" => false
    }.freeze
  end
end
