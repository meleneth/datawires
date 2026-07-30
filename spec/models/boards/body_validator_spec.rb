# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::BodyValidator do
  subject(:validator) { described_class.new(body) }

  let(:body) do
    {
      "version" => 1,
      "title" => "Datawires Board",
      "description" => "Workspace",
      "layout" => { "columns" => 2 },
      "sections" => [
        { "id" => "proposals", "kind" => "document_collection", "title" => "Open proposals" }
      ],
      "actions" => [
        { "id" => "submit", "kind" => "open_edit_affordance", "title" => "Submit proposal" }
      ]
    }
  end

  it "accepts a constrained version 1 board" do
    expect(validator).to be_valid
  end

  it "rejects unknown kinds and duplicate ids" do
    body["sections"] << { "id" => "proposals", "kind" => "analytics", "title" => "Other" }

    expect(validator).not_to be_valid
    expect(validator.errors).to include("sections[1].kind must be one of: document_collection, summary")
    expect(validator.errors).to include("sections ids must be unique: proposals")
  end
end
