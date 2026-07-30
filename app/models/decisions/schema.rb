# frozen_string_literal: true

module Decisions
  module Schema
    KEY = "decision"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => "Decision",
      "type" => "object",
      "required" => %w[decision_id meeting_id question_id question_version disposition evidence],
      "properties" => {
        "decision_id" => { "type" => "string", "format" => "uuid" },
        "meeting_id" => { "type" => "string", "format" => "uuid" },
        "question_id" => { "type" => "string", "format" => "uuid" },
        "question_version" => { "type" => "integer", "minimum" => 1 },
        "disposition" => { "type" => "string" },
        "evidence" => { "type" => "object" },
        "lineage" => { "type" => "object" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
