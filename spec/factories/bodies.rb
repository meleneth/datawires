# frozen_string_literal: true

FactoryBot.define do
  factory :body do
    body_document do
      domain = create(:domain)
      schema = create(:document, :with_schema_head_revision, domain:, key: Bodies::Schema::KEY, head_body: Bodies::Schema::BODY)
      create(:schema_wrapper, document: schema)
      create(:document, :with_head_revision, domain:, schema_document: schema, head_body: { "name" => "Assembly" })
    end
  end
end
