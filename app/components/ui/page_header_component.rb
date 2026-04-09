module Ui
  # frozen_string_literal: true

  class Ui::PageHeaderComponent < ApplicationComponent
    def initialize(text:)
      @text = text
    end

    private

    attr_reader :text
  end
end
