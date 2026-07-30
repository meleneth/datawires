# frozen_string_literal: true

module Proposals
  module Schema
    KEY = "proposal"
    BODY = {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "title" => "Proposal",
      "type" => "object",
      "required" => %w[title body_id content],
      "properties" => {
        "title" => { "type" => "string", "minLength" => 1 },
        "body_id" => { "type" => "string", "format" => "uuid" },
        "summary" => { "type" => "string" },
        "content" => { "type" => "object" }
      },
      "additionalProperties" => false
    }.freeze
  end
end
