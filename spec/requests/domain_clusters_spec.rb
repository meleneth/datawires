# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Domain clusters", type: :request do
  it "offers clusters when creating a new domain" do
    get new_domain_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cluster")
    expect(response.body).to include("Worldbuilding tools")
    expect(response.body).to include("Robert&#39;s Rules of Order")
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
      .and change(ViewAffordance, :count).by(1)

    domain = Domain.find_by!(name: "Novel")

    expect(response).to redirect_to(domain_path(domain))
    follow_redirect!
    expect(response.body).to include("person")
    expect(response.body).to include("place")
    expect(response.body).to include("thing")
    expect(response.body).to include("party")
    expect(response.body).to include("timeline-event")
  end

  it "creates a repository-mode domain pre-seeded with the roberts rules cluster" do
    expect {
      post domains_path, params: {
        domain: {
          name: "Board Meeting",
          cluster_key: Clusters::Catalog::ROBERTS_RULES
        }
      }
    }.to change(Domain, :count).by(1)
      .and change(SchemaWrapper, :count).by(4)
      .and change(EditAffordance, :count).by(4)
      .and change(ViewAffordance, :count).by(1)
      .and change(DomainCommit, :count).by(1)

    domain = Domain.find_by!(name: "Board Meeting")

    expect(domain).to be_repository_mode
    expect(domain.head_domain_commit).to be_present
    expect(response).to redirect_to(domain_path(domain))
    follow_redirect!
    expect(response.body).to include("agreement")
    expect(response.body).to include("motion")
    expect(response.body).to include("proceeding-event")
    expect(response.body).to include("meeting-state")
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
