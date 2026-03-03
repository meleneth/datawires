# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    domain
    sequence(:key) { |n| "doc-#{n}" }
    title { nil }
    head_revision { nil }

    trait :with_head_revision do
      transient do
        head_body { {} }
      end

      after(:create) do |doc, ev|
        rev = create(:revision, document: doc, body: ev.head_body)
        doc.update!(head_revision: rev)
      end
    end
  end
end
