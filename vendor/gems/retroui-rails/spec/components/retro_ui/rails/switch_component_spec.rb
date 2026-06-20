# frozen_string_literal: true

require "spec_helper"

RSpec.describe RetroUI::Rails::SwitchComponent, type: :component do
  it "renders a native checkbox switch" do
    fragment = render_component(described_class.new(name: "enabled", checked: true, html_options: { class: "custom" }))

    input = fragment.at_css("input")
    expect(input["type"]).to eq("checkbox")
    expect(input["role"]).to eq("switch")
    expect(input["name"]).to eq("enabled")
    expect(input["checked"]).to eq("checked")
    expect(input["aria-checked"]).to eq("true")
    expect(input["class"]).to include("checked:bg-primary")
    expect(input["class"]).to include("custom")
  end
end
