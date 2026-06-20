# frozen_string_literal: true

require "spec_helper"

RSpec.describe RetroUI::Rails::ButtonComponent, type: :component do
  it "renders a button" do
    fragment = render_component(described_class.new(label: "Start"))

    expect(fragment.at_css("button")["type"]).to eq("button")
    expect(fragment.at_css("button").text).to include("Start")
  end

  it "renders an anchor when href is provided" do
    fragment = render_component(described_class.new(label: "Docs", href: "/docs"))

    expect(fragment.at_css("a")["href"]).to eq("/docs")
    expect(fragment.at_css("button")).to be_nil
  end

  it "supports block content" do
    fragment = render_component(described_class.new(label: "Ignored")) { "Block wins" }

    expect(fragment.at_css("button").text).to include("Block wins")
    expect(fragment.at_css("button").text).not_to include("Ignored")
  end

  it "merges caller classes" do
    fragment = render_component(described_class.new(label: "Start", html_options: { class: "w-full custom-class" }))

    classes = fragment.at_css("button")["class"]
    expect(classes).to include("inline-flex")
    expect(classes).to include("w-full")
    expect(classes).to include("custom-class")
  end

  it "applies variant classes" do
    fragment = render_component(described_class.new(label: "Delete", variant: :destructive))

    expect(fragment.at_css("button")["class"]).to include("bg-destructive")
    expect(fragment.at_css("button")["class"]).to include("text-destructive-foreground")
  end

  it "applies size classes" do
    fragment = render_component(described_class.new(label: "Open", size: :lg))

    expect(fragment.at_css("button")["class"]).to include("h-12")
    expect(fragment.at_css("button")["class"]).to include("px-6")
  end

  it "rejects invalid variants" do
    expect { described_class.new(label: "Start", variant: :nope) }.to raise_error(ArgumentError, /Invalid variant/)
  end

  it "rejects invalid sizes" do
    expect { described_class.new(label: "Start", size: :xl) }.to raise_error(ArgumentError, /Invalid size/)
  end
end
