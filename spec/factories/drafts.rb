# frozen_string_literal: true

FactoryBot.define do
  factory :draft do
    document
    based_on_revision { nil }
    body { {} }
    created_by { nil }
  end
end
