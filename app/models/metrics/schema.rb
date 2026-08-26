# frozen_string_literal: true

module Metrics
  module Schema
    KEY = "datawires-metric"
    TITLE = "Datawires Metric"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "datawires:core/#{KEY}",
      "title" => TITLE,
      "type" => "object",
      "required" => %w[version key title value_type aggregation],
      "properties" => {
        "version" => { "const" => 1 },
        "key" => { "type" => "string" },
        "title" => { "type" => "string" },
        "description" => { "type" => "string" },
        "value_type" => { "enum" => %w[number count] },
        "unit" => { "type" => "string" },
        "dimensions" => { "type" => "array", "items" => { "type" => "string" } },
        "aggregation" => { "enum" => %w[count sum min max average last] },
        "correction_policy" => { "const" => "latest" },
        "rollup" => {
          "type" => "object", "required" => %w[bucket_seconds],
          "properties" => { "bucket_seconds" => { "type" => "integer", "minimum" => 1 } },
          "additionalProperties" => false
        },
        "derived" => {
          "type" => "object", "required" => %w[operation inputs],
          "properties" => {
            "operation" => { "enum" => %w[add subtract multiply divide] },
            "inputs" => { "type" => "array", "minItems" => 2, "items" => { "type" => "string" } }
          },
          "additionalProperties" => false
        }
      },
      "additionalProperties" => false
    }.freeze
  end
end
