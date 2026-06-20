# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RetroUI chart components", type: :component do
  let(:data) do
    [
      { month: "Jan", count: 12 },
      { month: "Feb", count: 18 }
    ]
  end

  it "renders a bar chart with D3 Stimulus values" do
    fragment = render_component(
      RetroUI::Rails::BarChartComponent.new(
        data: data,
        title: "Shipments",
        x_key: :month,
        y_key: :count
      )
    )

    wrapper = fragment.at_css("[data-controller]")
    expect(wrapper["data-controller"]).to include("retro-ui--chart")
    expect(wrapper["data-retro-ui--chart-type-value"]).to eq("bar")
    expect(wrapper["data-retro-ui--chart-x-key-value"]).to eq("month")
    expect(wrapper["data-retro-ui--chart-y-key-value"]).to eq("count")
    expect(JSON.parse(wrapper["data-retro-ui--chart-data-value"]).first).to include("month" => "Jan", "count" => 12)
    expect(fragment.at_css("h3").text).to eq("Shipments")
    expect(fragment.at_css("svg")["data-retro-ui--chart-target"]).to eq("svg")
  end

  it "renders line, area, and pie chart types" do
    expect(chart_type_for(RetroUI::Rails::LineChartComponent.new(data: data))).to eq("line")
    expect(chart_type_for(RetroUI::Rails::AreaChartComponent.new(data: data))).to eq("area")
    expect(chart_type_for(RetroUI::Rails::PieChartComponent.new(data: data, label_key: :month, value_key: :count))).to eq("pie")
  end

  it "ships a D3 controller that imports d3 and handles all chart types" do
    controller = Rails.root.join("../../app/javascript/retro_ui/rails/controllers/chart_controller.js").expand_path.read

    expect(controller).to include('import * as d3 from "d3"')
    expect(controller).to include('this.typeValue === "pie"')
    expect(controller).to include('this.typeValue === "area"')
    expect(controller).to include('this.typeValue === "line"')
  end

  def chart_type_for(component)
    render_component(component).at_css("[data-controller]")["data-retro-ui--chart-type-value"]
  end
end
