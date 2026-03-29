# frozen_string_literal: true

FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "domain-#{n}" }
  end
end
