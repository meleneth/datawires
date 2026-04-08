# frozen_string_literal: true

FactoryBot.define do
  factory :revision do
    document
    body { {} }
    message { "Initial revision" }
  end
end
