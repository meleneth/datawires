# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI utility components", type: :component do
  it "renders a decorative horizontal separator by default" do
    fragment = render_component(RetroUI::Rails::SeparatorComponent.new)

    separator = fragment.at_css("div")
    expect(separator["aria-hidden"]).to eq("true")
    expect(separator["class"]).to include("border-t-2")
  end

  it "renders a semantic vertical separator" do
    fragment = render_component(RetroUI::Rails::SeparatorComponent.new(orientation: :vertical, decorative: false))

    separator = fragment.at_css("div")
    expect(separator["role"]).to eq("separator")
    expect(separator["aria-orientation"]).to eq("vertical")
    expect(separator["class"]).to include("border-l-2")
  end

  it "rejects invalid separator orientations" do
    expect { RetroUI::Rails::SeparatorComponent.new(orientation: :diagonal) }.to raise_error(ArgumentError, /Invalid orientation/)
  end

  it "renders a skeleton with caller classes" do
    fragment = render_component(RetroUI::Rails::SkeletonComponent.new(html_options: { class: "h-8 w-full" }))

    skeleton = fragment.at_css("div")
    expect(skeleton["aria-hidden"]).to eq("true")
    expect(skeleton["class"]).to include("animate-pulse")
    expect(skeleton["class"]).to include("h-8")
  end

  it "renders progress with aria values and indicator width" do
    fragment = render_component(RetroUI::Rails::ProgressComponent.new(value: 25, max: 50))

    progress = fragment.at_css("div[role='progressbar']")
    indicator = progress.at_css("div")
    expect(progress["aria-valuenow"]).to eq("25.0")
    expect(progress["aria-valuemax"]).to eq("50.0")
    expect(indicator["class"]).to include("bg-primary")
    expect(indicator["style"]).to include("width: 50.0%;")
  end
end
