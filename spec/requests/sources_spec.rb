# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sources", type: :request do
  include ActiveJob::TestHelper

  it "creates an HTTP JSON source and queues a manual run" do
    domain = create(:domain)
    Projects::Install.call(domain:)

    expect {
      post domain_sources_path(domain), params: {
        source: {
          title: "Weather", url: "https://example.test/weather", every_seconds: "300",
          metric_key: "temperature", unit: "C", value_pointer: "/value", observed_at_pointer: "/at"
        }
      }
    }.to change(Source, :count).by(1)

    source = Source.order(:created_at).last
    expect(source.head_revision.body).to include("adapter" => "http_json", "schedule" => { "every_seconds" => 300 })
    expect(response).to redirect_to(domain_sources_path(domain))

    expect {
      post source_source_runs_path(source)
    }.to have_enqueued_job(Sources::ExecuteJob).with(source.id, trigger: "manual", actor_id: an_instance_of(String))
  end
end
