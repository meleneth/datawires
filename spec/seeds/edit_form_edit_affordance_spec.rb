# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/support/document_seed_helper")
require Rails.root.join("db/seeds/json_schema_2020_12")
require Rails.root.join("db/seeds/edit_form_schema")
require Rails.root.join("db/seeds/edit_form_edit_affordance")

RSpec.describe Seeds::EditFormEditAffordance do
  describe ".affordance_body" do
    it "is accepted by the edit affordance body validator" do
      validator = EditAffordances::BodyValidator.new(described_class.affordance_body)

      expect(validator).to be_valid
    end
  end

  describe ".seed!" do
    it "creates a default edit affordance for the edit-form schema" do
      Seeds::JsonSchema202012.seed!
      Seeds::EditFormSchema.seed!

      expect {
        described_class.seed!
      }.to change(EditAffordance, :count).by(1)

      edit_form_schema = Document.find_by!(key: Seeds::EditFormSchema::DOCUMENT_KEY)
      affordance = edit_form_schema.schema_wrapper.edit_affordances.sole

      expect(affordance.title).to eq("Default")
      expect(affordance.edit_document.key).to eq("edit-form-default-edit-affordance")
      expect(affordance.edit_document.schema_document).to eq(edit_form_schema)
      expect(affordance.body.fetch("screens").map { |screen| screen.fetch("id") }).to include(
        "main",
        "screen",
        "subform"
      )
    end

    it "is idempotent" do
      Seeds::JsonSchema202012.seed!
      Seeds::EditFormSchema.seed!
      described_class.seed!

      expect {
        described_class.seed!
      }.not_to change(EditAffordance, :count)
    end
  end
end
