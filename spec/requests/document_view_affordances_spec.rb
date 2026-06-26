# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document view affordances", type: :request do
  it "creates a view affordance from the schema page and opens the raw builder draft" do
    domain = create(:domain)
    schema = create_timeline_schema(domain: domain)

    get schema_path(schema.schema_wrapper)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New view affordance")

    expect {
      post schema_view_affordances_path(schema.schema_wrapper), params: {
        title: "Sequence"
      }
    }.to change(ViewAffordance, :count).by(1)
      .and change(Document, :count).by(1)
      .and change(Draft, :count).by(1)

    view_affordance = ViewAffordance.order(:created_at).last
    draft = view_affordance.view_document.drafts.sole

    expect(response).to redirect_to(draft_view_affordance_builder_path(draft))
    expect(draft.body).to include(
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => "Sequence",
      "config" => include("schema_key" => "timeline-event")
    )
  end

  it "continues an uncommitted view affordance draft from the schema page" do
    domain = create(:domain)
    schema = create_timeline_schema(domain: domain)
    result = CreateViewAffordance.call(schema_wrapper: schema.schema_wrapper, title: "Timeline", actor: current_actor)

    get schema_path(schema.schema_wrapper)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Continue editing")
    expect(response.body).to include(draft_schema_view_affordance_path(schema.schema_wrapper, result.view_affordance))

    expect {
      post draft_schema_view_affordance_path(schema.schema_wrapper, result.view_affordance)
    }.not_to change(Draft, :count)

    expect(response).to redirect_to(draft_view_affordance_builder_path(result.draft))
  end

  it "updates raw view affordance JSON and reports diagnostics" do
    domain = create(:domain)
    schema = create_timeline_schema(domain: domain)
    result = CreateViewAffordance.call(schema_wrapper: schema.schema_wrapper, title: "Timeline", actor: current_actor)

    get draft_view_affordance_builder_path(result.draft, tab: "raw")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("View affordance builder")
    expect(response.body).to include("Raw JSON")

    patch update_raw_draft_view_affordance_builder_path(result.draft), params: {
      body_json: JSON.pretty_generate(
        "version" => 1,
        "renderer" => "force_graph"
      )
    }

    expect(response).to redirect_to(draft_view_affordance_builder_path(result.draft, tab: "raw"))
    expect(result.draft.reload.body).to include("renderer" => "force_graph")

    get draft_view_affordance_builder_path(result.draft, tab: "diagnostics")

    expect(response.body).to include("renderer must be one of: timeline_d3")
  end

  it "updates timeline view settings through structured controls" do
    domain = create(:domain)
    schema = create_timeline_schema(domain: domain)
    result = CreateViewAffordance.call(schema_wrapper: schema.schema_wrapper, title: "Timeline", actor: current_actor)

    get draft_view_affordance_builder_path(result.draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Settings")
    expect(response.body).to include("Timeline schema key")

    patch update_settings_draft_view_affordance_builder_path(result.draft), params: {
      title: "Story Clock",
      renderer: "timeline_d3",
      schema_key: "timeline-event",
      relative_time_label: "Scene beat"
    }

    expect(response).to redirect_to(draft_view_affordance_builder_path(result.draft, tab: "settings"))
    expect(result.draft.reload.body).to include(
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => "Story Clock",
      "config" => include(
        "schema_key" => "timeline-event",
        "relative_time_label" => "Scene beat"
      )
    )

    get draft_view_affordance_builder_path(result.draft, tab: "diagnostics")

    expect(response.body).to include("No diagnostics.")
  end

  it "previews timeline views with the runtime D3 controller" do
    domain = create(:domain)
    schema = create_timeline_schema(domain: domain)
    result = CreateViewAffordance.call(schema_wrapper: schema.schema_wrapper, title: "Timeline", actor: current_actor)
    create_timeline_event(
      domain: domain,
      schema: schema,
      key: "arrival",
      title: "Arrival",
      relative_time: -2,
      summary: "The party arrives."
    )

    get draft_view_affordance_builder_path(result.draft, tab: "preview")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-controller=\"timeline-view\"")
    expect(response.body).to include("Arrival")
    expect(response.body).to include("The party arrives.")
  end

  it "previews documents from the configured timeline schema key" do
    domain = create(:domain)
    timeline_schema = create_timeline_schema(domain: domain)
    person_schema = create_person_schema(domain: domain)
    result = CreateViewAffordance.call(schema_wrapper: person_schema.schema_wrapper, title: "Timeline", actor: current_actor)
    create_timeline_event(
      domain: domain,
      schema: timeline_schema,
      key: "arrival",
      title: "Arrival",
      relative_time: -2,
      summary: "The party arrives."
    )

    get draft_view_affordance_builder_path(result.draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Timeline Event")

    patch update_settings_draft_view_affordance_builder_path(result.draft), params: {
      title: "Story Clock",
      renderer: "timeline_d3",
      schema_key: "timeline-event",
      relative_time_label: "Relative time"
    }

    get draft_view_affordance_builder_path(result.draft, tab: "preview")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Preview document: Arrival")
    expect(response.body).to include("data-controller=\"timeline-view\"")
    expect(response.body).to include("The party arrives.")
  end

  it "links and renders a seeded D3 timeline view without edit controls" do
    domain = create(:domain)
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: create(:user))

    timeline_schema = domain.documents.find_by!(key: "timeline-event")
    person_schema = domain.documents.find_by!(key: "person")
    person = create(
      :document,
      :with_head_revision,
      domain: domain,
      schema_document: person_schema,
      key: "ada",
      title: "Ada",
      head_body: {
        "name" => "Ada Lovelace"
      }
    )
    DocumentIndexes::Rebuild.call(document: person)
    first_event = create_timeline_event(
      domain: domain,
      schema: timeline_schema,
      key: "arrival",
      title: "Arrival",
      relative_time: -10,
      summary: "The party reaches the city.",
      participants: [
        {
          "kind" => "person",
          "key" => "ada",
          "role" => "witness"
        }
      ]
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
    expect(response.body).to include("Ada Lovelace")
    expect(response.body).to include("witness")
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

  def create_timeline_event(domain:, schema:, key:, title:, relative_time:, summary:, participants: [])
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
        "summary" => summary,
        "participants" => participants
      }
    )
  end

  def create_timeline_schema(domain:)
    schema = create(
      :document,
      :with_head_revision,
      domain: domain,
      key: "timeline-event",
      title: "Timeline Event",
      head_body: {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "datawires:test/timeline-event",
        "type" => "object",
        "required" => %w[relative_time title event_type],
        "properties" => {
          "relative_time" => { "type" => "integer" },
          "title" => { "type" => "string" },
          "event_type" => { "type" => "string" },
          "summary" => { "type" => "string" }
        }
      }
    )
    create(:schema_wrapper, document: schema)
    schema
  end

  def create_person_schema(domain:)
    schema = create(
      :document,
      :with_head_revision,
      domain: domain,
      key: "person",
      title: "Person",
      head_body: {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "datawires:test/person",
        "type" => "object",
        "required" => %w[name],
        "properties" => {
          "name" => { "type" => "string" }
        }
      }
    )
    create(:schema_wrapper, document: schema)
    schema
  end

  def current_actor
    User.find_or_create_by!(id: ApplicationController::DEV_USER_ID) do |user|
      user.name = "devUser"
    end
  end
end
