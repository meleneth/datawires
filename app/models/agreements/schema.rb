# frozen_string_literal: true

module Agreements
  module Schema
    KEY = "parliamentary-agreement"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => "Agreement",
      "type" => "object",
      "required" => %w[agreement_id decision_id title content adopted_at lineage],
      "properties" => {
        "agreement_id" => { "type" => "string", "format" => "uuid" },
        "decision_id" => { "type" => "string", "format" => "uuid" },
        "title" => { "type" => "string", "minLength" => 1 },
        "content" => { "type" => "object" },
        "adopted_at" => { "type" => "string" },
        "lineage" => { "type" => "object" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
