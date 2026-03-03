class FieldComponent < ApplicationComponent
  renders_one :actions

  STATES = {
    normal: { frame: "border-ls5-blue-3 bg-ls5-blue-1", label: "text-ink", hint: "text-ls5-blue-8", error: "text-ls5-red-7" },
    focus: { frame: "border-ls5-blue-4 bg-ls5-blue-1", label: "text-ink", hint: "text-ls5-blue-8", error: "text-ls5-red-7" },
    dirty: { frame: "border-ls5-yellow-4 bg-ls5-yellow-1", label: "text-ink", hint: "text-ls5-yellow-8", error: "text-ls5-red-7" },
    error: { frame: "border-ls5-red-6 bg-ls5-red-1", label: "text-ink", hint: "text-ls5-red-7", error: "text-ls5-red-7" },
    disabled: { frame: "border-ls5-violet-3 bg-ls5-violet-1", label: "text-ls5-violet-7", hint: "text-ls5-violet-7", error: "text-ls5-red-7" },
  }.freeze

  def initialize(
    name: nil,
    label: nil,
    hint: nil,
    errors: nil,
    state: :normal,
    required: false,
    disabled: false,
    compact: false,
    **html_options
  )
    @name = name
    @label = label
    @hint = hint
    @errors = normalize_errors(errors)
    @state = disabled ? :disabled : state
    @required = required
    @disabled = disabled
    @compact = compact
    @html_options = html_options
  end

  def frame_classes
    s = STATES.fetch(@state)
    cx(
      "rounded border p-3",
      (s[:frame]),
      (@compact ? "p-2" : nil),
      (@disabled ? "opacity-70" : nil),
      @html_options[:class]
    )
  end

  def header_classes
    cx("flex items-start gap-3", (@compact ? "mb-1" : "mb-2"))
  end

  def label_classes
    s = STATES.fetch(@state)
    cx("font-semibold", s[:label])
  end

  def meta_classes
    cx("mt-0.5 text-sm", STATES.fetch(@state)[:hint])
  end

  def error_classes
    cx("mt-1 text-sm font-semibold", STATES.fetch(@state)[:error])
  end

  def control_wrap_classes
    cx("mt-2", (@compact ? "mt-1" : nil))
  end

  def required_mark
    @required ? "*" : nil
  end

  def aria_invalid
    @errors.any? ? "true" : "false"
  end

  def describedby_id
    return nil unless @name.present?
    parts = []
    parts << "#{@name}-hint" if @hint.present?
    parts << "#{@name}-errors" if @errors.any?
    parts.any? ? parts.join(" ") : nil
  end

  def hint_id
    @name.present? ? "#{@name}-hint" : nil
  end

  def errors_id
    @name.present? ? "#{@name}-errors" : nil
  end

  private

  def normalize_errors(errors)
    case errors
    when nil then []
    when String then [errors]
    when Array then errors.compact.map(&:to_s)
    else [errors.to_s]
    end
  end
end
