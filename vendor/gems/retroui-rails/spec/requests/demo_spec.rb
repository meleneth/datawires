# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Demo page", type: :request do
  it "renders the component demo" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("RetroUI Rails")
    expect(response.body).to include("Autosave complete")
    expect(response.body).to include("Current component batches")
    expect(response.body).to include('data-controller="retro-ui--theme"')
    expect(response.body).to include('data-retro-ui--theme-target="label"')
    expect(response.body).to include('[data-theme="dark"]')
  end
end
