# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI avatar and aspect ratio components", type: :component do
  it "renders avatar composition" do
    fragment = render_component(RetroUI::Rails::AvatarComponent.new(html_options: { class: "h-12 w-12" })) do
      vc_test_controller.view_context.safe_join([
        vc_test_controller.view_context.render(RetroUI::Rails::AvatarImageComponent.new(src: "/avatar.png", alt: "Ada")),
        vc_test_controller.view_context.render(RetroUI::Rails::AvatarFallbackComponent.new(text: "AD"))
      ])
    end

    avatar = fragment.at_css("span")
    expect(avatar["class"]).to include("rounded")
    expect(avatar["class"]).to include("h-12")
    expect(fragment.at_css("img")["src"]).to eq("/avatar.png")
    expect(fragment.at_css("img")["alt"]).to eq("Ada")
    expect(fragment.css("span").last.text).to include("AD")
  end

  it "renders aspect ratio with style and classes" do
    fragment = render_component(RetroUI::Rails::AspectRatioComponent.new(ratio: "4/3", html_options: { class: "border-2" })) { "Media" }

    element = fragment.at_css("div")
    expect(element["style"]).to include("aspect-ratio: 4/3;")
    expect(element["class"]).to include("border-2")
  end
end
