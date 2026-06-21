# frozen_string_literal: true

FactoryBot.define do
  factory :edit_affordance do
    association :schema_wrapper
    edit_document do
      create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screen" => {
            "mode" => "page",
            "columns" => 12,
            "default_span" => 4,
            "commit_mode" => "review_screen"
          },
          "rows" => [
            [
              {
                "kind" => "commit",
                "span" => 12,
                "message_mode" => "hidden"
              }
            ]
          ]
        }
      )
    end
    sequence(:title) { |n| "Edit Affordance #{n}" }
  end
end
