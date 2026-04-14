# frozen_string_literal: true

FactoryBot.define do
  factory :view_affordance do
    association :for_schema_document, factory: :schema_document
    association :view_document, factory: %i[document with_plain_head_revision]
    sequence(:title) { |n| "View Affordance #{n}" }
  end
end
