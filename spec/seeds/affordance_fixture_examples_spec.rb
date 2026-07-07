# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/support/document_seed_helper")
require Rails.root.join("db/seeds/json_schema_2020_12")
require Rails.root.join("db/seeds/edit_form_schema")
require Rails.root.join("db/seeds/affordance_fixture_examples")

RSpec.describe Seeds::AffordanceFixtureExamples do
  describe ".fixtures" do
    it "defines one valid affordance for each fixture shape" do
      fixture_keys = described_class.fixtures.map { |fixture| fixture.fetch(:schema_key) }

      expect(fixture_keys).to contain_exactly(
        "fixture-flat-object",
        "fixture-nested-object",
        "fixture-object-array",
        "fixture-scalar-array",
        "fixture-mixed-workflow"
      )

      described_class.fixtures.each do |fixture|
        validator = EditAffordances::BodyValidator.new(fixture.fetch(:affordance_body))

        expect(validator).to be_valid, "#{fixture.fetch(:schema_key)} errors: #{validator.errors.join(", ")}"
      end
    end
  end

  describe ".seed!" do
    it "creates fixture schemas, example documents, and attached edit affordances" do
      Seeds::JsonSchema202012.seed!
      Seeds::EditFormSchema.seed!

      expect {
        described_class.seed!
      }.to change(EditAffordance, :count).by(5)

      domain = Domain.find_by!(name: described_class::DOMAIN_NAME)

      described_class.fixtures.each do |fixture|
        schema_document = Document.find_by!(domain: domain, key: fixture.fetch(:schema_key))
        example_document = Document.find_by!(domain: domain, key: fixture.fetch(:example_key))
        edit_document = Document.find_by!(domain: domain, key: fixture.fetch(:edit_key))
        affordance = schema_document.schema_wrapper.edit_affordances.sole

        expect(schema_document.schema_wrapper).to be_public
        expect(example_document.schema_document).to eq(schema_document)
        expect(edit_document.schema_document.key).to eq(Seeds::EditFormSchema::DOCUMENT_KEY)
        expect(affordance.title).to eq("Fixture")
        expect(affordance).to be_public
        expect(affordance.edit_document).to eq(edit_document)
      end
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
