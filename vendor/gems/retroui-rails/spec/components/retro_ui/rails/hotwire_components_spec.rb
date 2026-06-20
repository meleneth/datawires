# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI Hotwire components", type: :component do
  it "renders accordion controller targets and actions" do
    fragment = render_component(RetroUI::Rails::AccordionComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::AccordionItemComponent.new) do
        vc_test_controller.view_context.render(RetroUI::Rails::AccordionTriggerComponent.new(text: "Question")) +
          vc_test_controller.view_context.render(RetroUI::Rails::AccordionContentComponent.new) { "Answer" }
      end
    end

    expect(fragment.at_css("[data-controller]")["data-controller"]).to include("retro-ui--accordion")
    expect(fragment.at_css("button")["data-action"]).to include("click->retro-ui--accordion#toggle")
    expect(fragment.at_css("[data-retro-ui--accordion-target='content']")).to be_present
  end

  it "renders tabs controller targets and value params" do
    fragment = render_component(RetroUI::Rails::TabsComponent.new(default_value: "preview")) do
      vc_test_controller.view_context.render(RetroUI::Rails::TabsListComponent.new) do
        vc_test_controller.view_context.render(RetroUI::Rails::TabsTriggerComponent.new(value: "preview", text: "Preview"))
      end +
        vc_test_controller.view_context.render(RetroUI::Rails::TabsContentComponent.new(value: "preview")) { "Panel" }
    end

    expect(fragment.at_css("[data-controller]")["data-controller"]).to include("retro-ui--tabs")
    expect(fragment.at_css("button")["data-retro-ui--tabs-value-param"]).to eq("preview")
    expect(fragment.at_css("[role='tabpanel']")["data-retro-ui--tabs-value"]).to eq("preview")
  end

  it "uses explicit attribute reads in the tabs controller for double-hyphen data names" do
    controller = Rails.root.join("../../app/javascript/retro_ui/rails/controllers/tabs_controller.js").expand_path.read

    expect(controller).to include('getAttribute("data-retro-ui--tabs-value-param")')
    expect(controller).to include('getAttribute("data-retro-ui--tabs-value")')
  end

  it "renders dialog trigger content and close wiring" do
    fragment = render_component(RetroUI::Rails::DialogComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::DialogTriggerComponent.new(label: "Open")) +
        vc_test_controller.view_context.render(RetroUI::Rails::DialogContentComponent.new) do
          vc_test_controller.view_context.render(RetroUI::Rails::DialogCloseComponent.new) +
            vc_test_controller.view_context.render(RetroUI::Rails::DialogTitleComponent.new(text: "Title"))
        end
    end

    expect(fragment.at_css("[data-controller]")["data-controller"]).to include("retro-ui--dialog")
    expect(fragment.at_css("button")["data-action"]).to include("click->retro-ui--dialog#open")
    expect(fragment.at_css("[role='dialog']")).to be_present
    expect(fragment.css("button").last["data-action"]).to include("click->retro-ui--dialog#close")
  end

  it "renders dropdown menu wiring" do
    fragment = render_component(RetroUI::Rails::DropdownMenuComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::DropdownMenuTriggerComponent.new(label: "Menu")) +
        vc_test_controller.view_context.render(RetroUI::Rails::DropdownMenuContentComponent.new) do
          vc_test_controller.view_context.render(RetroUI::Rails::DropdownMenuItemComponent.new(text: "Profile"))
        end
    end

    expect(fragment.at_css("[data-controller]")["data-controller"]).to include("retro-ui--dropdown-menu")
    expect(fragment.at_css("button")["data-action"]).to include("click->retro-ui--dropdown-menu#toggle")
    expect(fragment.at_css("[role='menu']")).to be_present
  end

  it "renders popover wiring" do
    fragment = render_component(RetroUI::Rails::PopoverComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::PopoverTriggerComponent.new(label: "Open")) +
        vc_test_controller.view_context.render(RetroUI::Rails::PopoverContentComponent.new) { "Popover" }
    end

    expect(fragment.at_css("[data-controller]")["data-controller"]).to include("retro-ui--popover")
    expect(fragment.at_css("button")["data-action"]).to include("click->retro-ui--popover#toggle")
    expect(fragment.at_css("[data-retro-ui--popover-target='content']")).to be_present
  end

  it "renders tooltip wiring" do
    fragment = render_component(RetroUI::Rails::TooltipComponent.new) do
      vc_test_controller.view_context.render(RetroUI::Rails::TooltipTriggerComponent.new(text: "Hover")) +
        vc_test_controller.view_context.render(RetroUI::Rails::TooltipContentComponent.new(text: "Tooltip"))
    end

    expect(fragment.at_css("[data-controller]")["data-controller"]).to include("retro-ui--tooltip")
    expect(fragment.at_css("[tabindex]")["data-action"]).to include("mouseenter->retro-ui--tooltip#show")
    expect(fragment.at_css("[role='tooltip']")).to be_present
  end
end
