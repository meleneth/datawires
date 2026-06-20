# frozen_string_literal: true

FactoryBot.define do
  factory :draft do
    document
    created_by factory: :user
    based_on_revision { document.head_revision }
    body { based_on_revision&.body || {} }

    trait :with_name_affordance do
      edit_affordance_body do
        {
          "version" => 1,
          "rows" => [
            {
              "ptr" => "/name",
              "label" => "Name",
              "widget" => "text"
            }
          ]
        }
      end
    end
  end
end
