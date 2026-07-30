# frozen_string_literal: true

FactoryBot.define do
  factory :role_assignment do
    association :actor, factory: :user
    association :scope, factory: :body
    role { "chair" }
    effective_from { 1.day.ago }
    provenance { { "source" => "spec" } }
  end
end
