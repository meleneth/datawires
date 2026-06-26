# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewAffordances::BodyValidator do
  def validator_for(body)
    described_class.new(body)
  end

  it "accepts the current timeline view DSL shape" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => "Timeline",
      "config" => {
        "schema_key" => "timeline-event",
        "relative_time_label" => "Relative time"
      }
    )

    expect(validator).to be_valid
  end

  it "requires a JSON object body" do
    validator = validator_for([])

    expect(validator.errors).to include("body must be a JSON object")
  end

  it "requires an explicit supported version" do
    missing = validator_for("renderer" => "timeline_d3")
    unsupported = validator_for("version" => 99, "renderer" => "timeline_d3")
    invalid = validator_for("version" => [], "renderer" => "timeline_d3")

    expect(missing.errors).to include("version is required")
    expect(unsupported.errors).to include("version 99 is not supported")
    expect(invalid.errors).to include("version must be an integer")
  end

  it "requires a supported renderer" do
    missing = validator_for("version" => 1)
    unsupported = validator_for("version" => 1, "renderer" => "force_graph")

    expect(missing.errors).to include("renderer is required")
    expect(unsupported.errors).to include("renderer must be one of: timeline_d3")
  end

  it "validates timeline renderer metadata" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => [],
      "config" => {
        "schema_key" => 12,
        "relative_time_label" => false
      }
    )

    expect(validator.errors).to include(
      "title must be a string",
      "config/schema_key must be a string",
      "config/relative_time_label must be a string"
    )
  end

  it "requires config to be an object when present" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "timeline_d3",
      "config" => []
    )

    expect(validator.errors).to include("config must be an object")
  end
end
