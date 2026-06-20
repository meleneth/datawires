# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI alert components", type: :component do
  it "renders an alert wrapper with default role and classes" do
    fragment = render_component(RetroUI::Rails::AlertComponent.new) { "Saved" }

    alert = fragment.at_css("div")
    expect(alert["role"]).to eq("status")
    expect(alert["class"]).to include("border-2")
    expect(alert["class"]).to include("bg-card")
  end

  it "renders destructive alert role and classes" do
    fragment = render_component(RetroUI::Rails::AlertComponent.new(variant: :destructive)) { "Failed" }

    alert = fragment.at_css("div")
    expect(alert["role"]).to eq("alert")
    expect(alert["class"]).to include("bg-destructive")
  end

  it "rejects invalid variants" do
    expect { RetroUI::Rails::AlertComponent.new(variant: :secondary) }.to raise_error(ArgumentError, /Invalid variant/)
  end

  it "renders title classes" do
    fragment = render_component(RetroUI::Rails::AlertTitleComponent.new) { "Heads up" }

    expect(fragment.at_css("h5")["class"]).to include("font-head")
    expect(fragment.at_css("h5")["class"]).to include("font-medium")
  end

  it "renders description classes" do
    fragment = render_component(RetroUI::Rails::AlertDescriptionComponent.new) { "Everything is fine." }

    expect(fragment.at_css("div")["class"]).to include("text-sm")
  end
end
