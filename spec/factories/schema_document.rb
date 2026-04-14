# frozen_string_literal: true

FactoryBot.define do
  factory :schema_document do
    association :document, factory: %i[document with_schema_head_revision]
  end
end
