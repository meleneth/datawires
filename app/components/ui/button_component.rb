# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  TONES = {
    primary: "bg-ls5-blue-4 text-ink-inverse hover:bg-ls5-blue-5",
    warning: "bg-ls5-yellow-4 text-ls5-yellow-8 hover:bg-ls5-yellow-5",
    danger: "bg-ls5-red-6 text-ink-inverse hover:bg-ls5-red-7",
    subtle: "bg-ls5-violet-1 text-ls5-violet-7 hover:bg-ls5-violet-2",
  }.freeze

  SIZES = {
    sm: "px-2 py-1 text-sm",
    md: "px-3 py-2 text-sm",
    lg: "px-4 py-3 text-base",
  }.freeze

  def initialize(tone: :primary, size: :md, disabled: false, type: :button, **html_options)
    @tone = tone
    @size = size
    @disabled = disabled
    @type = type
    @html_options = html_options
  end

  def classes
    cx(
      "inline-flex items-center justify-center rounded font-medium transition",
      "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-ls5-blue-3",
      TONES.fetch(@tone),
      SIZES.fetch(@size),
      ("opacity-50 cursor-not-allowed" if @disabled),
      @html_options[:class]
    )
  end
end
