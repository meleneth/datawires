# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observations::Correct do
  it "appends a retraction without mutating the original" do
    source = create(:source)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    original = source.observations.create!(domain: source.domain, source_run: run,
      configuration_revision: source.head_revision, observation_type: "metric", metric_key: "temperature",
      numeric_value: 10, payload: {}, observed_at: Time.current, effective_at: Time.current, recorded_at: Time.current)

    correction = described_class.call(observation: original, kind: "retract")

    expect(correction).to have_attributes(corrects_observation: original, correction_kind: "retract", numeric_value: nil)
    expect(original.reload.numeric_value).to eq(10)
  end
end
