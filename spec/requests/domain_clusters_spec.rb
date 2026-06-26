# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Domain clusters", type: :request do
  it "offers clusters when creating a new domain" do
    get new_domain_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cluster")
    expect(response.body).to include("Worldbuilding tools")
  end

  it "creates a domain pre-seeded with the worldbuilding cluster" do
    expect {
      post domains_path, params: {
        domain: {
          name: "Novel",
          cluster_key: Clusters::Catalog::WORLD_BUILDING
        }
      }
    }.to change(Domain, :count).by(1)
      .and change(SchemaWrapper, :count).by(5)
      .and change(EditAffordance, :count).by(5)

    domain = Domain.find_by!(name: "Novel")

    expect(response).to redirect_to(domain_path(domain))
    follow_redirect!
    expect(response.body).to include("person")
    expect(response.body).to include("place")
    expect(response.body).to include("thing")
    expect(response.body).to include("party")
    expect(response.body).to include("timeline-event")
  end

  it "rejects unknown clusters without creating the domain" do
    expect {
      post domains_path, params: {
        domain: {
          name: "Bad Cluster",
          cluster_key: "missing"
        }
      }
    }.not_to change(Domain, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Cluster is not available.")
  end
end
