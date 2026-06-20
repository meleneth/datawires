# frozen_string_literal: true

require "spec_helper"

RSpec.describe RetroUI::Rails::CardComponent, type: :component do
  it "renders root wrapper classes" do
    fragment = render_component(described_class.new) { "Card" }

    classes = fragment.at_css("div")["class"]
    expect(classes).to include("inline-block")
    expect(classes).to include("border-2")
    expect(classes).to include("bg-card")
    expect(classes).to include("text-card-foreground")
  end
end
