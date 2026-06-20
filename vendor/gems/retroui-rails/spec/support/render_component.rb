# frozen_string_literal: true

module RenderComponent
  def render_component(component, &block)
    html = vc_test_controller.view_context.render(component, &block)
    Nokogiri::HTML.fragment(html)
  end

  def vc_test_controller
    @vc_test_controller ||= ApplicationController.new
  end
end

RSpec.configure do |config|
  config.include RenderComponent, type: :component
end
