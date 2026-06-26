# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Domain commits", type: :request do
  it "lists repository history for a domain" do
    domain = create(:domain, name: "Board History")
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: nil)
    commit = domain.reload.head_domain_commit

    get domain_path(domain)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Repository history")

    get domain_domain_commits_path(domain)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Board History Repository History")
    expect(response.body).to include("Seed Robert&#39;s Rules of Order cluster")
    expect(response.body).to include(commit.state_hash)
    expect(response.body).to include(domain_domain_commit_path(domain, commit))
  end

  it "shows the documents captured by one domain commit" do
    domain = create(:domain)
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: nil)
    commit = domain.reload.head_domain_commit

    get domain_domain_commit_path(domain, commit)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Domain Commit")
    expect(response.body).to include("Seed Robert&#39;s Rules of Order cluster")
    expect(response.body).to include(commit.state_hash)
    expect(response.body).to include("Document Revisions")
    expect(response.body).to include("agreement")
    expect(response.body).to include("domain-home-page")
    expect(response.body).to include("Revision hash")
  end
end
