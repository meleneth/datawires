# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordances::Versions do
  describe ".upgrade" do
    it "adds the current version to empty affordance bodies" do
      expect(described_class.upgrade({})).to eq("version" => 1)
    end

    it "preserves current version affordance bodies" do
      body = {
        "version" => 1,
        "rows" => []
      }

      expect(described_class.upgrade(body)).to eq(body)
    end

    it "rejects unsupported affordance versions" do
      expect {
        described_class.upgrade("version" => 99)
      }.to raise_error(
        EditAffordances::Versions::UnsupportedVersionError,
        /unsupported edit affordance version/
      )
    end
  end
end
