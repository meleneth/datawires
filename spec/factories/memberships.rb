# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    body
    association :actor, factory: :user
    status { "active" }
    effective_from { 1.day.ago }
    provenance { { "source" => "spec" } }
  end
end
