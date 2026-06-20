# frozen_string_literal: true

require "spec_helper"

RSpec.describe RetroUI::Rails::BadgeComponent, type: :component do
  it "renders label text and default classes" do
    fragment = render_component(described_class.new(label: "Beta"))

    badge = fragment.at_css("span")
    expect(badge.text).to include("Beta")
    expect(badge["class"]).to include("bg-primary")
    expect(badge["class"]).to include("border-2")
  end

  it "supports block content" do
    fragment = render_component(described_class.new(label: "Ignored")) { "Ready" }

    expect(fragment.at_css("span").text).to include("Ready")
    expect(fragment.at_css("span").text).not_to include("Ignored")
  end

  it "applies variant classes and merges caller classes" do
    fragment = render_component(described_class.new(variant: :secondary, html_options: { class: "uppercase" })) { "New" }

    classes = fragment.at_css("span")["class"]
    expect(classes).to include("bg-secondary")
    expect(classes).to include("uppercase")
  end

  it "rejects invalid variants" do
    expect { described_class.new(variant: :ghost) }.to raise_error(ArgumentError, /Invalid variant/)
  end
end
