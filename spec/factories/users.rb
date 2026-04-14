# spec/factories/users.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    avatar { nil }
  end
end
