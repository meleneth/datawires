# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:external_id) { |n| "keystone-user-#{n}" }
    sequence(:email) { |n| "user#{n}@example.test" }
    avatar { nil }
  end
end
