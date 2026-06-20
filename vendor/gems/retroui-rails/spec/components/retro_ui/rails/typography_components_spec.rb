# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI typography components", type: :component do
  it "renders configured typography element" do
    fragment = render_component(RetroUI::Rails::TypographyComponent.new(as: :h2, text: "Heading", html_options: { class: "mb-4" }))

    heading = fragment.at_css("h2")
    expect(heading.text).to include("Heading")
    expect(heading["class"]).to include("text-3xl")
    expect(heading["class"]).to include("mb-4")
  end

  it "rejects invalid typography elements" do
    expect { RetroUI::Rails::TypographyComponent.new(as: :script) }.to raise_error(ArgumentError, /Invalid typography element/)
  end

  it "renders code" do
    fragment = render_component(RetroUI::Rails::CodeComponent.new(text: "bundle exec rspec"))

    expect(fragment.at_css("code").text).to include("bundle exec rspec")
    expect(fragment.at_css("code")["class"]).to include("font-mono")
  end

  it "renders kbd" do
    fragment = render_component(RetroUI::Rails::KbdComponent.new(text: "⌘K"))

    expect(fragment.at_css("kbd").text).to include("⌘K")
    expect(fragment.at_css("kbd")["class"]).to include("shadow-xs")
  end
end
