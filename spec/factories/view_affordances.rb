# frozen_string_literal: true

FactoryBot.define do
  factory :view_affordance do
    association :schema_wrapper
    view_document do
      create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "renderer" => "timeline_d3",
          "title" => "Timeline"
        }
      )
    end
    sequence(:title) { |n| "View Affordance #{n}" }
  end
end
