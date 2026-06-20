# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI table components", type: :component do
  it "renders a composed table" do
    fragment = render_component(RetroUI::Rails::TableComponent.new(html_options: { class: "min-w-96" })) do
      vc_test_controller.view_context.safe_join([
        vc_test_controller.view_context.render(RetroUI::Rails::TableCaptionComponent.new) { "Invoices" },
        vc_test_controller.view_context.render(RetroUI::Rails::TableHeaderComponent.new) do
          vc_test_controller.view_context.render(RetroUI::Rails::TableRowComponent.new) do
            vc_test_controller.view_context.render(RetroUI::Rails::TableHeadComponent.new) { "Name" }
          end
        end,
        vc_test_controller.view_context.render(RetroUI::Rails::TableBodyComponent.new) do
          vc_test_controller.view_context.render(RetroUI::Rails::TableRowComponent.new) do
            vc_test_controller.view_context.render(RetroUI::Rails::TableCellComponent.new) { "RetroUI" }
          end
        end,
        vc_test_controller.view_context.render(RetroUI::Rails::TableFooterComponent.new) do
          vc_test_controller.view_context.render(RetroUI::Rails::TableRowComponent.new) do
            vc_test_controller.view_context.render(RetroUI::Rails::TableCellComponent.new) { "Total" }
          end
        end
      ])
    end

    expect(fragment.at_css("table")["class"]).to include("w-full")
    expect(fragment.at_css("table")["class"]).to include("min-w-96")
    expect(fragment.at_css("caption")["class"]).to include("text-muted-foreground")
    expect(fragment.at_css("thead")["class"]).to include("border-b-2")
    expect(fragment.at_css("tbody")).not_to be_nil
    expect(fragment.at_css("tfoot")["class"]).to include("bg-muted")
    expect(fragment.at_css("tr")["class"]).to include("hover:bg-muted")
    expect(fragment.at_css("th")["class"]).to include("font-head")
    expect(fragment.at_css("td").text).to include("RetroUI")
  end
end
