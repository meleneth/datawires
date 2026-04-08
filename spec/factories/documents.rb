# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    domain
    sequence(:key) { |n| "document-#{n}" }
    title { "Document" }

    transient do
      head_body { {} }
      head_message { "Initial revision" }
    end

    trait :with_head_revision do
      after(:create) do |document, evaluator|
        revision = create(
          :revision,
          document: document,
          body: evaluator.head_body,
          message: evaluator.head_message
        )

        document.update!(head_revision: revision)
      end
    end

    trait :with_schema_head_revision do
      with_head_revision

      transient do
        head_body do
          {
            "$schema" => Document::JSON_SCHEMA_2020_12,
            "$id" => "http://#{domain.name}/schemas/#{key}",
            "type" => "object",
            "properties" => {}
          }
        end
      end
    end

    trait :with_plain_head_revision do
      with_head_revision

      transient do
        head_body do
          {
            "title" => "Example",
            "event_type" => "note"
          }
        end
      end
    end
  end
end
