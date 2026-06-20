module Ui
  # frozen_string_literal: true

  class Ui::CardComponent < ApplicationComponent
    def initialize(**html_options)
      @html_options = html_options
    end
  end
end
