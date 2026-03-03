# frozen_string_literal: true

FactoryBot.define do
  factory :revision do
    document
    parent_revision { nil }
    body { {} }
    message { nil }
    created_by { nil }
  end
end
