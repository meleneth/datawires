# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/domains", type: :request do
  it "renders the index, new page, and an active visible domain" do
    domain = create(:domain)

    get domains_url
    expect(response).to be_successful
    get new_domain_url
    expect(response).to be_successful
    expect(response.body).to include("Project workspace")
    get domain_url(domain)
    expect(response).to be_successful
  end

  it "creates a blank domain owned by the current user" do
    expect {
      post domains_url, params: { domain: { name: "Signals", public: false, cluster_key: "" } }
    }.to change(Domain, :count).by(1)

    domain = Domain.find_by!(name: "Signals")
    expect(response).to redirect_to(domain_url(domain))
    expect(domain.owner.name).to eq("devUser")
    expect(domain.project_affordance).to be_nil
  end

  it "creates a domain with an independently selected project workspace" do
    expect {
      post domains_url, params: {
        domain: { name: "Signals", public: false, cluster_key: Clusters::Catalog::WORLD_BUILDING,
                  project_workspace: "1" }
      }
    }.to change(ProjectAffordance, :count).by(1)

    domain = Domain.find_by!(name: "Signals")
    expect(response).to redirect_to(domain_url(domain))
    expect(domain.project_affordance).to be_present
    expect(domain.project_affordance.title).to eq("Signals")
    expect(domain.documents.find_by(key: "person")).to be_present
  end

  it "rejects unknown clusters before persistence" do
    expect {
      post domains_url, params: { domain: { name: "Signals", cluster_key: "not-installed" } }
    }.not_to change(Domain, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Cluster is not available")
  end

  it "returns model validation failures in JSON" do
    create(:domain, name: "Taken")

    post domains_url(format: :json), params: { domain: { name: "Taken", cluster_key: "" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("name")).to include("has already been taken")
  end

  it "updates valid attributes and rejects invalid updates" do
    domain = create(:domain)

    patch domain_url(domain), params: { domain: { name: "Renamed", public: true } }
    expect(response).to redirect_to(domain_url(domain))
    expect(domain.reload).to have_attributes(name: "Renamed", public: true)

    patch domain_url(domain, format: :json), params: { domain: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("name")).to include("can't be blank")
  end

  it "archives a populated cluster domain without deleting owned history" do
    domain = create(:domain)
    Clusters::SeedDomain.call(
      domain:, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: create(:user)
    )
    document_ids = domain.documents.ids
    revision_ids = Revision.where(document_id: document_ids).ids

    delete domain_url(domain)

    expect(response).to redirect_to(domains_url)
    expect(domain.reload).to be_archived
    expect(Document.where(id: document_ids).count).to eq(document_ids.length)
    expect(Revision.where(id: revision_ids).count).to eq(revision_ids.length)
    get domain_url(domain)
    expect(response).to have_http_status(:not_found)
  end
end
