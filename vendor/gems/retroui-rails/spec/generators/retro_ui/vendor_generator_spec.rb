# frozen_string_literal: true

require "spec_helper"
require "generators/retro_ui/vendor/vendor_generator"
require "securerandom"

RSpec.describe RetroUI::Generators::VendorGenerator, type: :generator do
  tests RetroUI::Generators::VendorGenerator

  destination File.expand_path("../../tmp/vendor_generator", __dir__)

  before do
    self.class.destination File.expand_path("../../tmp/vendor_generator_#{SecureRandom.hex(8)}", __dir__)
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
  end

  it "copies expected files" do
    run_generator

    expect(destination_file("app/components/retro_ui/button_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/button_component.html.erb")).to exist
    expect(destination_file("app/components/retro_ui/card_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/badge_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/alert_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/input_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/textarea_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/label_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/checkbox_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/radio_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/select_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/separator_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/skeleton_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/progress_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/table_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/table_cell_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/avatar_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/aspect_ratio_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/breadcrumb_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/pagination_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/typography_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/code_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/kbd_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/switch_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/toast_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/toast_close_component.html.erb")).to exist
    expect(destination_file("app/components/retro_ui/accordion_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/tabs_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/dialog_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/dropdown_menu_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/popover_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/tooltip_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/bar_chart_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/area_chart_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/line_chart_component.rb")).to exist
    expect(destination_file("app/components/retro_ui/pie_chart_component.rb")).to exist
    expect(destination_file("app/assets/stylesheets/retro_ui/theme.css")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/accordion_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/chart_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/tabs_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/dialog_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/dropdown_menu_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/popover_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/tooltip_controller.js")).to exist
    expect(destination_file("app/javascript/controllers/retro_ui/toast_controller.js")).to exist
  end

  it "rewrites namespaces from RetroUI::Rails to RetroUI" do
    run_generator

    content = destination_file("app/components/retro_ui/button_component.rb").read
    expect(content).to include("RetroUI::ButtonComponent")
    expect(content).not_to include("RetroUI::Rails::ButtonComponent")
    expect(content).not_to include("module Rails")
    expect(content).not_to include("RetroUI::ClassNames")
    expect(content).to include("def class_names(*values)")

    chart_content = destination_file("app/components/retro_ui/area_chart_component.rb").read
    expect(chart_content).to include("class RetroUI::AreaChartComponent < RetroUI::ChartComponent")
  end

  it "copies Stimulus controllers" do
    run_generator

    content = destination_file("app/javascript/controllers/retro_ui/toast_controller.js").read
    expect(content).to include('from "@hotwired/stimulus"')
    expect(content).to include("dismiss(event)")
  end

  it "does not overwrite without --force" do
    run_generator
    original = destination_file("app/components/retro_ui/button_component.rb").read

    run_generator
    expect(destination_file("app/components/retro_ui/button_component.rb").read).to eq(original)
  end

  def destination_file(path)
    Pathname.new(destination_root).join(path)
  end
end
