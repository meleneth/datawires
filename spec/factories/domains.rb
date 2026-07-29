# frozen_string_literal: true

FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "domain-#{n}" }
    owner factory: :user
    public { false }
  end
end
