# frozen_string_literal: true

FactoryBot.define do
  factory :edit_affordance do
    association :for_schema_document, factory: [ :document, :with_schema_head_revision ]
    association :affordance_document, factory: [ :document, :with_plain_head_revision ]
    sequence(:name) { |n| "affordance-#{n}" }
  end
end
