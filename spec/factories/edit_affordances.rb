# frozen_string_literal: true

FactoryBot.define do
  factory :edit_affordance do
    association :for_schema_document, factory: :schema_document
    association :edit_document, factory: %i[document with_plain_head_revision]
    sequence(:title) { |n| "Edit Affordance #{n}" }
  end
end
