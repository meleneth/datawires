# frozen_string_literal: true

FactoryBot.define do
  factory :render_view do
    association :for_schema_document, factory: [ :document, :with_schema_head_revision ]
    association :view_document, factory: [ :document, :with_plain_head_revision ]
    sequence(:name) { |n| "view-#{n}" }
  end
end
