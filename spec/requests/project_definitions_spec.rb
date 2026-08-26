# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project definitions", type: :request do
  let(:domain) { create(:domain).tap { |value| Projects::Install.call(domain: value) } }

  it "creates, rotates, revokes, and assigns encrypted source credentials" do
    post domain_source_credentials_path(domain), params: {
      source_credential: { name: "weather-api", secret: "Bearer first" }
    }
    credential = domain.source_credentials.sole
    expect(response).to redirect_to(domain_source_credentials_path(domain))
    expect(credential.encrypted_payload).not_to include("Bearer first")
    expect(credential.secret).to eq("headers" => { "Authorization" => "Bearer first" })

    patch domain_source_credential_path(domain, credential), params: {
      source_credential: { name: "weather-api", secret: "Bearer second" }
    }
    expect(credential.reload.secret.dig("headers", "Authorization")).to eq("Bearer second")
    expect(credential.rotated_at).to be_present

    source = create(:source, domain:)
    patch source_path(source), params: { source: { source_credential_id: credential.id } }
    expect(source.reload.source_credential).to eq(credential)

    patch domain_source_credential_path(domain, credential), params: {
      source_credential: { name: credential.name, revoke: "1" }
    }
    expect(credential.reload).not_to be_active
  end

  it "creates versioned metric and reusable query definitions and opens their drafts" do
    post domain_metric_definitions_path(domain), params: { metric: {
      key: "temperature", title: "Temperature", description: "Outdoor temperature", value_type: "number",
      unit: "C", dimensions: "site, sensor, site", aggregation: "average"
    } }
    metric = domain.metric_definitions.sole
    expect(metric.body).to include("dimensions" => %w[site sensor], "aggregation" => "average")
    expect(metric.metric_document.schema_document.key).to eq(Metrics::Schema::KEY)

    post domain_query_definitions_path(domain), params: { query: {
      key: "daily-temperature", title: "Daily temperature", metric_key: "temperature",
      aggregate: "average", window_seconds: "86400", bucket_seconds: "3600"
    } }
    query = domain.query_definitions.sole
    expect(query.body).to include("metric_key" => "temperature", "window_seconds" => 86_400,
      "bucket_seconds" => 3600)
    expect(query.query_document.schema_document.key).to eq(Queries::Schema::KEY)

    expect {
      post document_draft_path(metric.metric_document)
      post document_draft_path(query.query_document)
    }.to change(Draft, :count).by(2)
  end

  it "keeps project-native definition management unavailable to legacy domains" do
    legacy = create(:domain)

    get domain_source_credentials_path(legacy)
    expect(response).to have_http_status(:not_found)
    get domain_metric_definitions_path(legacy)
    expect(response).to have_http_status(:not_found)
    get domain_query_definitions_path(legacy)
    expect(response).to have_http_status(:not_found)
  end
end
