# frozen_string_literal: true

module Meetings
  module Schema
    KEY = "meeting"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => "Meeting",
      "type" => "object",
      "required" => %w[title body_id scheduled_at],
      "properties" => {
        "title" => { "type" => "string", "minLength" => 1 },
        "body_id" => { "type" => "string", "format" => "uuid" },
        "scheduled_at" => { "type" => "string", "format" => "date-time" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
