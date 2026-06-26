# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainHomeLinks do
  it "resolves domain, repository, schema, document, and view links from the domain-home document" do
    domain = create(:domain)
    schema = create(:document, :with_schema_head_revision, domain: domain, key: "person")
    wrapper = create(:schema_wrapper, document: schema)
    person = create(:document, :with_head_revision, domain: domain, schema_document: schema, key: "ada")
    view_document = create(
      :document,
      :with_head_revision,
      domain: domain,
      head_body: {
        "version" => 1,
        "renderer" => "timeline_d3",
        "title" => "Timeline"
      }
    )
    view = create(:view_affordance, schema_wrapper: wrapper, view_document: view_document, title: "Timeline")
    create(
      :document,
      :with_head_revision,
      domain: domain,
      key: described_class::DOCUMENT_KEY,
      head_body: {
        "groups" => [
          {
            "title" => "Start",
            "links" => [
              { "kind" => "schema", "title" => "People", "schema_key" => "person" },
              { "kind" => "domain", "title" => "Domain" },
              { "kind" => "repository_history", "title" => "History" },
              { "kind" => "document", "title" => "Ada", "document_key" => "ada" },
              { "kind" => "view", "title" => "Ada Timeline", "document_key" => "ada", "schema_key" => "person", "view_title" => "Timeline" }
            ]
          }
        ]
      }
    )

    groups = described_class.for(domain)

    expect(groups.sole).to include("title" => "Start")
    expect(groups.sole.fetch("links")).to include(
      include("title" => "People", "href" => Rails.application.routes.url_helpers.schema_path(wrapper)),
      include("title" => "Domain", "href" => Rails.application.routes.url_helpers.domain_path(domain)),
      include("title" => "History", "href" => Rails.application.routes.url_helpers.domain_domain_commits_path(domain)),
      include("title" => "Ada", "href" => Rails.application.routes.url_helpers.document_path(person)),
      include("title" => "Ada Timeline", "href" => Rails.application.routes.url_helpers.document_view_affordance_path(person, view))
    )
  end

  it "omits links that cannot be resolved" do
    domain = create(:domain)
    create(
      :document,
      :with_head_revision,
      domain: domain,
      key: described_class::DOCUMENT_KEY,
      head_body: {
        "groups" => [
          {
            "title" => "Broken",
            "links" => [
              { "kind" => "document", "title" => "Missing", "document_key" => "missing" }
            ]
          }
        ]
      }
    )

    expect(described_class.for(domain)).to eq([])
  end
end
