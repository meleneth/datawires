# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateBody do
  it "creates a schema-backed Body and editable draft" do
    domain = create(:domain)
    actor = create(:user)

    result = described_class.call(domain:, name: "General Assembly", actor:)

    expect(result.body).to be_persisted
    expect(result.document.schema_document.key).to eq(Bodies::Schema::KEY)
    expect(result.document.body).to eq("name" => "General Assembly")
    expect(result.draft.created_by).to eq(actor)
    expect(result.document.schema_document.schema_wrapper).to be_present
    expect(result.body.memberships.effective_at(Time.current).find_by(actor:)).to be_present
    expect(result.body.role_assignments.effective_at(Time.current).find_by(actor:, role: "chair")).to be_present
  end
end
