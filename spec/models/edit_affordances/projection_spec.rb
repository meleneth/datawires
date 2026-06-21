# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordances::Projection do
  it "freezes projected rows, screens, bindings, and diagnostics" do
    projection = described_class.new(
      rows: [],
      screens: [],
      bindings: [],
      diagnostics: []
    )

    expect(projection.rows).to be_frozen
    expect(projection.screens).to be_frozen
    expect(projection.bindings).to be_frozen
    expect(projection.diagnostics).to be_frozen
  end

  it "exposes default column count" do
    projection = described_class.new(
      rows: [],
      defaults: described_class::Defaults.new(column_count: 6)
    )

    expect(projection.defaults.column_count).to eq(6)
  end
end
