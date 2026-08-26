# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observation do
  it "is append-only and pins source configuration lineage" do
    source = create(:source)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    observation = source.observations.create!(domain: source.domain, source_run: run,
      configuration_revision: source.head_revision, observation_type: "metric", payload: { "value" => 12 },
      observed_at: Time.current, effective_at: Time.current, recorded_at: Time.current)

    expect(observation.configuration_revision).to eq(source.head_revision)
    expect { observation.update!(payload: {}) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { observation.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
