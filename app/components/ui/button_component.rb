module Ui
  # frozen_string_literal: true

  class Ui::ButtonComponent < ApplicationComponent
    VARIANTS = {
      primary: :default,
      warning: :secondary,
      danger: :destructive,
      subtle: :outline,
    }.freeze

    SIZES = {
      sm: :sm,
      md: :md,
      lg: :lg,
    }.freeze

    def initialize(tone: :primary, size: :md, disabled: false, type: :button, **html_options)
      @variant = VARIANTS.fetch(tone)
      @size = SIZES.fetch(size)
      @disabled = disabled
      @type = type
      @html_options = html_options
    end

    def retro_options
      @html_options.merge(type: @type, disabled: @disabled)
    end
  end
end
