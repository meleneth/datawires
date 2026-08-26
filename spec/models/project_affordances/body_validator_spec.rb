# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectAffordances::BodyValidator do
  it "accepts the complete version 1 navigation vocabulary" do
    body = { "version" => 1, "title" => "Signals", "description" => "Operations", "groups" => [
      { "title" => "Project", "links" => described_class::LINK_KINDS.map { |kind| { "kind" => kind, "title" => kind } } }
    ] }

    expect(described_class.new(body)).to be_valid
  end

  it "reports top-level shape and metadata failures without cascading" do
    expect(described_class.new(nil).errors).to eq([ "body must be an object" ])
    expect(described_class.new({ "version" => 2, "title" => "", "description" => 1, "groups" => nil }).errors).to eq([
      "version must be 1", "title must be a non-empty string", "description must be a string",
      "groups must be an array"
    ])
  end

  it "reports malformed group and link shapes" do
    body = { "version" => 1, "title" => "Signals", "groups" => [
      nil,
      { "title" => "", "links" => nil },
      { "title" => "Valid", "links" => [ nil, { "kind" => "unknown", "title" => "" } ] }
    ] }

    expect(described_class.new(body).errors).to include(
      "groups[0] must be an object", "groups[1].title must be a non-empty string",
      "groups[1].links must be an array", "groups[2].links[0] must be an object",
      "groups[2].links[1].kind must be one of: domain, repository_history, schema, document, view, board",
      "groups[2].links[1].title must be a non-empty string"
    )
  end
end
