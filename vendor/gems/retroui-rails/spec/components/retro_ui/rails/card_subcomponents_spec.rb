# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI card subcomponents", type: :component do
  it "renders CardHeaderComponent expected classes" do
    fragment = render_component(RetroUI::Rails::CardHeaderComponent.new) { "Header" }

    expect(fragment.at_css("div")["class"]).to include("flex flex-col justify-start p-4")
  end

  it "renders CardTitleComponent expected classes" do
    fragment = render_component(RetroUI::Rails::CardTitleComponent.new) { "Title" }

    expect(fragment.at_css("h3")["class"]).to include("font-head text-2xl font-medium mb-2")
  end

  it "renders CardDescriptionComponent expected classes" do
    fragment = render_component(RetroUI::Rails::CardDescriptionComponent.new) { "Description" }

    expect(fragment.at_css("p")["class"]).to include("text-muted-foreground")
  end

  it "renders CardContentComponent expected classes" do
    fragment = render_component(RetroUI::Rails::CardContentComponent.new) { "Content" }

    expect(fragment.at_css("div")["class"]).to include("p-4")
  end
end
