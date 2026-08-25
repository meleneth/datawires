# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::Install do
  it "creates a dedicated project document without changing domain home" do
    domain = create(:domain)
    home = create(:document, :with_plain_head_revision, domain:, key: DomainHomeLinks::DOCUMENT_KEY,
      head_body: { "title" => "Existing", "groups" => [ { "title" => "Project", "links" => [] } ] })
    old_schema = home.schema_document

    project = described_class.call(domain:, title: "Existing")

    expect(project.project_document).not_to eq(home)
    expect(project.project_document.key).to eq("project-affordance")
    expect(project.project_document.body).to include("version" => 1, "title" => "Existing")
    expect(home.reload.schema_document).to eq(old_schema)
  end

  it "is idempotent" do
    domain = create(:domain)
    first = described_class.call(domain:)

    expect { described_class.call(domain:) }.not_to change(Revision, :count)
    expect(described_class.call(domain:)).to eq(first)
  end
end
