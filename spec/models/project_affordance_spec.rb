# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectAffordance do
  it "exposes versioned project metadata for its domain" do
    domain = create(:domain)
    project = Projects::Install.call(domain:, title: "Signals", description: "Private telemetry")

    expect(project).to have_attributes(domain:, title: "Signals", description: "Private telemetry")
    expect(project.project_document.schema_document.key).to eq(ProjectAffordances::Schema::KEY)
    expect(domain.reload).to be_project
  end

  it "rejects a project document from another domain" do
    domain = create(:domain)
    project = Projects::Install.call(domain: create(:domain))

    affordance = described_class.new(domain:, project_document: project.project_document)

    expect(affordance).not_to be_valid
    expect(affordance.errors[:project_document]).to include("must belong to the project domain")
  end

  it "rejects invalid project affordance content" do
    domain = create(:domain)
    project = Projects::Install.call(domain:)
    revision = project.project_document.revisions.create!(body: { "version" => 2 }, parent_revision: project.head_revision)
    project.project_document.update!(head_revision: revision)

    expect(project).not_to be_valid
    expect(project.errors[:project_document]).to include("version must be 1")
  end
end
