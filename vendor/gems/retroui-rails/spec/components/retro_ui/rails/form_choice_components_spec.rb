# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI choice form components", type: :component do
  it "renders a checkbox with checked state and classes" do
    fragment = render_component(RetroUI::Rails::CheckboxComponent.new(name: "agree", checked: true, html_options: { class: "mt-1" }))

    input = fragment.at_css("input")
    expect(input["type"]).to eq("checkbox")
    expect(input["name"]).to eq("agree")
    expect(input["value"]).to eq("1")
    expect(input["checked"]).to eq("checked")
    expect(input["class"]).to include("accent-primary")
    expect(input["class"]).to include("mt-1")
  end

  it "renders a radio with value and classes" do
    fragment = render_component(RetroUI::Rails::RadioComponent.new(name: "plan", value: "pro"))

    input = fragment.at_css("input")
    expect(input["type"]).to eq("radio")
    expect(input["name"]).to eq("plan")
    expect(input["value"]).to eq("pro")
    expect(input["class"]).to include("rounded-full")
  end

  it "renders a select from option pairs" do
    fragment = render_component(RetroUI::Rails::SelectComponent.new(name: "size", options: [["Small", "s"], ["Large", "l"]], selected: "l"))

    select = fragment.at_css("select")
    expect(select["name"]).to eq("size")
    expect(select["class"]).to include("border-2")
    expect(fragment.css("option").map(&:text)).to eq(["Small", "Large"])
    expect(fragment.at_css('option[value="l"]')["selected"]).to eq("selected")
  end

  it "lets select block content win over option pairs" do
    fragment = render_component(RetroUI::Rails::SelectComponent.new(options: ["Ignored"])) do
      '<option value="custom">Custom</option>'.html_safe
    end

    expect(fragment.css("option").map(&:text)).to eq(["Custom"])
  end
end
