# frozen_string_literal: true

FactoryBot.define do
  factory :event_stream do
    domain
    stream_type { "meeting" }
    subject_id { SecureRandom.uuid }
    revision { 0 }
  end
end
