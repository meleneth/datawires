# frozen_string_literal: true

require "spec_helper"

RSpec.describe RetroUI::Rails::Engine do
  it "loads as a Rails engine" do
    expect(described_class).to be < ::Rails::Engine
  end

  it "ships the theme asset" do
    path = described_class.root.join("app/assets/stylesheets/retro_ui/rails/theme.css")
    expect(path).to exist
    expect(path.read).to include("--primary")
  end
end
