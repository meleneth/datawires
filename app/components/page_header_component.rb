# frozen_string_literal: true

class PageHeaderComponent < ApplicationComponent
  def initialize(text:)
    @text = text
  end

  private

  attr_reader :text
end
