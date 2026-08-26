# frozen_string_literal: true

FactoryBot.define do
  factory :source do
    association :domain
    enabled { true }
    status { "idle" }

    source_document do
      schema = create(:document, :with_schema_head_revision, domain:, key: Sources::Schema::KEY, head_body: Sources::Schema::BODY)
      create(:schema_wrapper, document: schema)
      create(:document, :with_head_revision, domain:, schema_document: schema, head_body: {
        "version" => 1,
        "title" => "Weather",
        "adapter" => "http_json",
        "config" => { "url" => "https://example.test/weather", "method" => "GET" },
        "observation" => { "type" => "metric", "metric_key" => "temperature", "value_pointer" => "/value" }
      })
    end
  end
end
