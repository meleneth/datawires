# frozen_string_literal: true

FactoryBot.define do
  factory :view_affordance do
    association :schema_wrapper
    association :view_document, factory: %i[document with_plain_head_revision]
    sequence(:title) { |n| "View Affordance #{n}" }
  end
end
