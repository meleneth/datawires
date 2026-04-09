# frozen_string_literal: true

class SchemaRibbonMenuItem
  attr_reader :label, :path, :url

  def initialize(label:, path:, url:, current:)
    @label = label
    @path = path
    @url = url
    @current = current
  end

  def current?
    @current
  end
end
