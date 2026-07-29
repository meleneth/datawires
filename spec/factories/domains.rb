# frozen_string_literal: true

FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "domain-#{n}" }
    owner do
      User.find_or_create_by!(id: ApplicationController::DEV_USER_ID) do |user|
        user.name = "devUser"
      end
    end
    public { false }
  end
end
