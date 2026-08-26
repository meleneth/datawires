# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectAffordances::Navigation do
  it "resolves every supported project link through records in the project domain" do
    domain = create(:domain)
    project = Projects::Install.call(domain:)
    schema = create(:document, :with_schema_head_revision, domain:, key: "signal")
    wrapper = create(:schema_wrapper, document: schema)
    document = create(:document, :with_head_revision, domain:, schema_document: schema, key: "temperature")
    view_document = create(:document, :with_head_revision, domain:, head_body: {
      "version" => 1, "renderer" => "timeline_d3", "title" => "Details"
    })
    view = create(:view_affordance, schema_wrapper: wrapper, view_document:, title: "Details")
    board = CreateBoard.call(schema_wrapper: wrapper, title: "Signals", actor: domain.owner).board
    replace_body(project, groups: [ { "title" => "Observe", "links" => [
      { "kind" => "domain", "title" => "Domain" },
      { "kind" => "repository_history", "title" => "History" },
      { "kind" => "schema", "title" => "Signals", "schema_key" => "signal" },
      { "kind" => "document", "title" => "Temperature", "document_key" => "temperature" },
      { "kind" => "view", "title" => "Details", "document_key" => "temperature", "view_title" => "Details" },
      { "kind" => "board", "title" => "Board", "board_title" => "Signals" }
    ] } ])

    links = described_class.for(project).sole.fetch("links")

    expect(links.map { |link| link["href"] }).to eq([
      Rails.application.routes.url_helpers.domain_path(domain),
      Rails.application.routes.url_helpers.domain_domain_commits_path(domain),
      Rails.application.routes.url_helpers.schema_path(wrapper),
      Rails.application.routes.url_helpers.document_path(document),
      Rails.application.routes.url_helpers.document_view_affordance_path(document, view),
      Rails.application.routes.url_helpers.board_path(board)
    ])
  end

  it "uses fallbacks and omits malformed, unknown, and cross-domain links" do
    domain = create(:domain)
    project = Projects::Install.call(domain:)
    foreign = create(:document, :with_head_revision, domain: create(:domain), key: "foreign")
    expect(foreign).to be_persisted
    replace_body(project, groups: [ "invalid", { "links" => [
      "invalid",
      { "kind" => "unknown" },
      { "kind" => "document", "document_key" => "missing" },
      { "kind" => "document", "document_key" => "foreign" },
      { "kind" => "domain", "description" => 123 }
    ] } ])

    expect(described_class.for(project)).to eq([
      { "title" => "Project", "links" => [
        { "title" => Rails.application.routes.url_helpers.domain_path(domain), "description" => "123",
          "href" => Rails.application.routes.url_helpers.domain_path(domain) }
      ] }
    ])
  end

  it "selects the first titled view when a view title is omitted" do
    domain = create(:domain)
    project = Projects::Install.call(domain:)
    schema = create(:document, :with_schema_head_revision, domain:, key: "signal")
    wrapper = create(:schema_wrapper, document: schema)
    document = create(:document, :with_head_revision, domain:, schema_document: schema, key: "temperature")
    %w[Zulu Alpha].each do |title|
      view_document = create(:document, :with_head_revision, domain:, head_body: {
        "version" => 1, "renderer" => "timeline_d3", "title" => title
      })
      create(:view_affordance, schema_wrapper: wrapper, view_document:, title:)
    end
    replace_body(project, groups: [ { "links" => [
      { "kind" => "view", "document_key" => "temperature", "schema_key" => "signal" }
    ] } ])

    href = described_class.for(project).sole.fetch("links").sole.fetch("href")

    expect(href).to eq(Rails.application.routes.url_helpers.document_view_affordance_path(
      document, wrapper.view_affordances.find_by!(title: "Alpha")
    ))
  end

  def replace_body(project, groups:)
    revision = project.project_document.revisions.create!(
      body: project.body.merge("groups" => groups), parent_revision: project.head_revision
    )
    project.project_document.update!(head_revision: revision)
  end
end
