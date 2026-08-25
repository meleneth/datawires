# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project affordances", type: :request do
  it "enables an independent project workspace for a legacy domain" do
    domain = create(:domain)
    home = create(:document, :with_plain_head_revision, domain:, key: DomainHomeLinks::DOCUMENT_KEY,
      head_body: { "title" => "Legacy home", "groups" => [] })

    expect {
      post domain_project_affordance_path(domain)
    }.to change(ProjectAffordance, :count).by(1)

    expect(response).to redirect_to(domain_path(domain))
    expect(domain.reload.project_affordance.project_document).not_to eq(home)

    get domain_path(domain)
    expect(response.body).to include("Project workspace")
    expect(response.body).to include("Edit project configuration")
  end
end
