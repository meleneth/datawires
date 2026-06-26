# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document view affordances", type: :request do
  it "links and renders a seeded D3 timeline view without edit controls" do
    domain = create(:domain)
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: create(:user))

    timeline_schema = domain.documents.find_by!(key: "timeline-event")
    first_event = create_timeline_event(
      domain: domain,
      schema: timeline_schema,
      key: "arrival",
      title: "Arrival",
      relative_time: -10,
      summary: "The party reaches the city."
    )
    create_timeline_event(
      domain: domain,
      schema: timeline_schema,
      key: "council",
      title: "Council",
      relative_time: 5,
      summary: "A decision is made."
    )

    view_affordance = timeline_schema.schema_wrapper.view_affordances.sole

    get document_path(first_event)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("View affordances")
    expect(response.body).to include(document_view_affordance_path(first_event, view_affordance))

    get document_view_affordance_path(first_event, view_affordance)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Timeline")
    expect(response.body).to include("data-controller=\"timeline-view\"")
    expect(response.body).to include("Arrival")
    expect(response.body).to include("Council")
    expect(response.body).to include("The party reaches the city.")
    expect(response.body).not_to include("<input")
    expect(response.body).not_to include("<textarea")
    expect(response.body).not_to include("<select")
  end

  it "exposes seeded view affordances from the schema page" do
    domain = create(:domain)
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: create(:user))

    timeline_schema = domain.documents.find_by!(key: "timeline-event")
    event = create_timeline_event(
      domain: domain,
      schema: timeline_schema,
      key: "departure",
      title: "Departure",
      relative_time: 1,
      summary: "The story starts moving."
    )
    view_affordance = timeline_schema.schema_wrapper.view_affordances.sole

    get schema_path(timeline_schema.schema_wrapper)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("View affordances")
    expect(response.body).to include("Timeline")
    expect(response.body).to include("Documents using this schema")
    expect(response.body).to include(document_view_affordance_path(event, view_affordance))
  end

  def create_timeline_event(domain:, schema:, key:, title:, relative_time:, summary:)
    create(
      :document,
      :with_head_revision,
      domain: domain,
      schema_document: schema,
      key: key,
      title: title,
      head_body: {
        "relative_time" => relative_time,
        "event_type" => "general",
        "title" => title,
        "summary" => summary
      }
    )
  end
end
