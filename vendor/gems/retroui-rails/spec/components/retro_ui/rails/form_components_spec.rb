# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI form components", type: :component do
  it "renders an input with attributes and classes" do
    fragment = render_component(RetroUI::Rails::InputComponent.new(type: :email, name: "email", value: "a@example.com", html_options: { class: "peer" }))

    input = fragment.at_css("input")
    expect(input["type"]).to eq("email")
    expect(input["name"]).to eq("email")
    expect(input["value"]).to eq("a@example.com")
    expect(input["class"]).to include("border-2")
    expect(input["class"]).to include("peer")
  end

  it "renders a textarea with value and classes" do
    fragment = render_component(RetroUI::Rails::TextareaComponent.new(name: "message", value: "Hello"))

    textarea = fragment.at_css("textarea")
    expect(textarea["name"]).to eq("message")
    expect(textarea.text).to include("Hello")
    expect(textarea["class"]).to include("min-h-24")
  end

  it "lets textarea block content win over value" do
    fragment = render_component(RetroUI::Rails::TextareaComponent.new(value: "Ignored")) { "Block" }

    expect(fragment.at_css("textarea").text).to include("Block")
    expect(fragment.at_css("textarea").text).not_to include("Ignored")
  end

  it "renders a label with for attribute and caller classes" do
    fragment = render_component(RetroUI::Rails::LabelComponent.new(text: "Email", for_id: "email", html_options: { class: "block" }))

    label = fragment.at_css("label")
    expect(label["for"]).to eq("email")
    expect(label.text).to include("Email")
    expect(label["class"]).to include("font-head")
    expect(label["class"]).to include("block")
  end
end
