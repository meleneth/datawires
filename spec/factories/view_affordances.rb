# frozen_string_literal: true

FactoryBot.define do
  factory :view_affordance do
    association :for_schema_document, factory: [ :document, :with_schema_head_revision ]
    association :view_document, factory: [ :document, :with_plain_head_revision ]
    sequence(:title) { |n| "view-#{n}" }
  end
end
