# spec/lib/document_path_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentPath do
  describe "#document_ptr" do
    it "returns the normalized document pointer" do
      expect(described_class.new("/mobilis/name").document_ptr).to eq("/mobilis/name")
    end
  end

  describe "#schema_ptr" do
    it "maps slash root to canonical root" do
      expect(described_class.new("/").schema_ptr).to eq("")
    end

    it "maps empty root to canonical root" do
      expect(described_class.new("").schema_ptr).to eq("")
    end

    it "maps a top-level document path into schema properties" do
      expect(described_class.new("/mobilis").schema_ptr).to eq("/properties/mobilis")
    end

    it "maps a nested document path into nested schema properties" do
      expect(described_class.new("/mobilis/name").schema_ptr).to eq("/properties/mobilis/properties/name")
    end
  end
end
