# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Keystone auth", type: :request do
  it "creates the current user from Keystone identity headers" do
    get domains_path, headers: keystone_headers(id: "ks-123", name: "Ada Lovelace", email: "ada@example.test")

    expect(response).to have_http_status(:ok)

    user = User.find_by!(external_id: "ks-123")
    expect(user.name).to eq("Ada Lovelace")
    expect(user.email).to eq("ada@example.test")
  end

  it "creates the current user from the auth proxy remote user header" do
    get domains_path, headers: { "X-Remote-User" => "Meleneth" }

    expect(response).to have_http_status(:ok)

    user = User.find_by!(external_id: "Meleneth")
    expect(user.name).to eq("Meleneth")
  end

  it "creates the current user from oauth2-proxy forwarded identity headers" do
    get domains_path,
      headers: {
        "X-Forwarded-User" => "oidc-subject-123",
        "X-Forwarded-Preferred-Username" => "Meleneth",
        "X-Forwarded-Email" => "meleneth@deva.station"
      }

    expect(response).to have_http_status(:ok)

    user = User.find_by!(external_id: "oidc-subject-123")
    expect(user.name).to eq("Meleneth")
    expect(user.email).to eq("meleneth@deva.station")
  end

  it "links the current user name to their profile" do
    get domains_path, headers: keystone_headers(id: "ks-profile", name: "Grace Hopper", email: "grace@example.test")

    user = User.find_by!(external_id: "ks-profile")
    expect(response.body).to include(%(href="/users/#{user.id}"))
    expect(response.body).to include("Grace Hopper")

    get user_path(user), headers: keystone_headers(id: "ks-profile", name: "Grace Hopper", email: "grace@example.test")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Grace Hopper")
    expect(response.body).to include("grace@example.test")
    expect(response.body).to include("Log out")
    expect(response.body).to include("/oauth2/sign_out?")
    expect(response.body).to include("protocol%2Fopenid-connect%2Flogout")
    expect(response.body).to include("id_token_hint%3D%7Bid_token%7D")
  end

  it "does not show the logout control on another user's profile" do
    other = create(:user, name: "Other User")

    get user_path(other), headers: keystone_headers(id: "ks-profile", name: "Grace Hopper")

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Log out")
  end

  it "assigns new domains to the Keystone user" do
    post domains_path,
      params: { domain: { name: "Private Notes", cluster_key: "" } },
      headers: keystone_headers(id: "ks-owner", name: "Owner")

    domain = Domain.find_by!(name: "Private Notes")
    expect(domain.owner.external_id).to eq("ks-owner")
    expect(domain).to be_private
  end

  it "shows owned private domains and public domains, but not other private domains" do
    owner = create(:user, external_id: "ks-owner")
    other = create(:user)
    owned = create(:domain, name: "Owned Private", owner: owner, public: false)
    public_domain = create(:domain, name: "Public Domain", owner: other, public: true)
    hidden = create(:domain, name: "Hidden Private", owner: other, public: false)

    get domains_path, headers: keystone_headers(id: "ks-owner", name: "Owner")

    expect(response.body).to include(owned.name)
    expect(response.body).to include(public_domain.name)
    expect(response.body).not_to include(hidden.name)
  end

  def keystone_headers(id:, name:, email: nil)
    {
      "X-Keystone-User-Id" => id,
      "X-Keystone-User-Name" => name,
      "X-Keystone-User-Email" => email
    }.compact
  end
end
