# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI breadcrumb and pagination components", type: :component do
  it "renders breadcrumb composition" do
    fragment = render_component(RetroUI::Rails::BreadcrumbComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::BreadcrumbListComponent.new) do
        vc_test_controller.view_context.safe_join([
          vc_test_controller.view_context.render(RetroUI::Rails::BreadcrumbItemComponent.new) do
            vc_test_controller.view_context.render(RetroUI::Rails::BreadcrumbLinkComponent.new(href: "/", text: "Home"))
          end,
          vc_test_controller.view_context.render(RetroUI::Rails::BreadcrumbSeparatorComponent.new),
          vc_test_controller.view_context.render(RetroUI::Rails::BreadcrumbItemComponent.new) do
            vc_test_controller.view_context.render(RetroUI::Rails::BreadcrumbPageComponent.new(text: "Docs"))
          end
        ])
      end
    end

    expect(fragment.at_css("nav")["aria-label"]).to eq("Breadcrumb")
    expect(fragment.at_css("ol")["class"]).to include("flex")
    expect(fragment.at_css("a")["href"]).to eq("/")
    expect(fragment.at_css("span[aria-current='page']").text).to include("Docs")
  end

  it "renders active pagination link" do
    fragment = render_component(RetroUI::Rails::PaginationComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::PaginationContentComponent.new) do
        vc_test_controller.view_context.render(RetroUI::Rails::PaginationItemComponent.new) do
          vc_test_controller.view_context.render(RetroUI::Rails::PaginationLinkComponent.new(href: "/p/2", label: "2", active: true))
        end
      end
    end

    link = fragment.at_css("a")
    expect(fragment.at_css("nav")["aria-label"]).to eq("Pagination")
    expect(fragment.at_css("ul")["class"]).to include("gap-1")
    expect(link["aria-current"]).to eq("page")
    expect(link["class"]).to include("bg-primary")
  end
end
