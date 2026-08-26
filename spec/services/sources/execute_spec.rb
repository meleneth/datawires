# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sources::Execute do
  class SpecSourceAdapter
    VERSION = "spec-1"

    def self.validate(_config, path: "config")
      []
    end

    def initialize(configuration:, credential:)
    end

    def call
      Sources::Adapters::Result.new(
        items: [ { "value" => "12.5", "at" => "2026-08-25T12:00:00Z", "site" => "north" } ],
        metadata: { "fixture" => true }
      )
    end
  end

  before do
    Datawires::Providers.sources.register("spec", SpecSourceAdapter)
  end

  it "appends typed observations with exact configuration provenance" do
    source = create_source

    run = described_class.call(source:, trigger: "manual", idempotency_key: "run-1")
    observation = run.observations.sole

    expect(run).to have_attributes(status: "succeeded", adapter: "spec", adapter_version: "spec-1", observation_count: 1)
    expect(observation).to have_attributes(metric_key: "temperature", unit: "C", numeric_value: 12.5,
      configuration_revision: source.head_revision, observed_at: Time.zone.parse("2026-08-25T12:00:00Z"))
    expect(observation.dimensions).to eq("site" => "north")
    expect(observation.provenance).to include("configuration_revision_id" => source.head_revision.id,
      "source_run_id" => run.id, "adapter_version" => "spec-1")
  end

  it "returns the existing run for an idempotent retry" do
    source = create_source
    first = described_class.call(source:, trigger: "manual", idempotency_key: "same")

    expect { described_class.call(source:, trigger: "manual", idempotency_key: "same") }.not_to change(Observation, :count)
    expect(source.source_runs.find_by!(idempotency_key: "same")).to eq(first)
  end

  def create_source
    domain = create(:domain)
    schema = create(:document, :with_schema_head_revision, domain:, key: Sources::Schema::KEY, head_body: Sources::Schema::BODY)
    create(:schema_wrapper, document: schema)
    document = create(:document, :with_head_revision, domain:, schema_document: schema, head_body: {
      "version" => 1,
      "title" => "Temperature",
      "adapter" => "spec",
      "config" => {},
      "observation" => {
        "type" => "metric", "metric_key" => "temperature", "unit" => "C", "value_pointer" => "/value",
        "observed_at_pointer" => "/at", "dimensions" => { "site" => "/site" }
      }
    })
    described_source = Source.create!(domain:, source_document: document)
    described_source
  end
end
