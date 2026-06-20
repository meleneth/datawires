# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI toast components", type: :component do
  it "renders a toast viewport" do
    fragment = render_component(RetroUI::Rails::ToastViewportComponent.new) { "Toasts" }

    viewport = fragment.at_css("div")
    expect(viewport["class"]).to include("fixed")
    expect(viewport["class"]).to include("max-w-sm")
    expect(viewport["aria-live"]).to eq("polite")
  end

  it "renders a default toast with Stimulus wiring" do
    fragment = render_component(RetroUI::Rails::ToastComponent.new(duration: 3000)) { "Saved" }

    toast = fragment.at_css("div")
    expect(toast["role"]).to eq("status")
    expect(toast["class"]).to include("bg-card")
    expect(toast["data-controller"]).to eq("retro-ui--toast")
    expect(toast["data-retro-ui--toast-duration-value"]).to eq("3000")
    expect(toast["data-state"]).to eq("open")
  end

  it "renders destructive toast role and classes" do
    fragment = render_component(RetroUI::Rails::ToastComponent.new(variant: :destructive)) { "Failed" }

    toast = fragment.at_css("div")
    expect(toast["role"]).to eq("alert")
    expect(toast["class"]).to include("bg-destructive")
  end

  it "rejects invalid toast variants" do
    expect { RetroUI::Rails::ToastComponent.new(variant: :secondary) }.to raise_error(ArgumentError, /Invalid variant/)
  end

  it "renders title and description text" do
    title = render_component(RetroUI::Rails::ToastTitleComponent.new(text: "Saved"))
    description = render_component(RetroUI::Rails::ToastDescriptionComponent.new(text: "Your changes landed."))

    expect(title.at_css("div")["class"]).to include("font-head")
    expect(title.text).to include("Saved")
    expect(description.at_css("div")["class"]).to include("text-sm")
    expect(description.text).to include("Your changes landed.")
  end

  it "renders a close button wired to dismiss" do
    fragment = render_component(RetroUI::Rails::ToastCloseComponent.new)

    button = fragment.at_css("button")
    expect(button["type"]).to eq("button")
    expect(button["aria-label"]).to eq("Dismiss")
    expect(button["data-action"]).to include("click->retro-ui--toast#dismiss")
  end
end
