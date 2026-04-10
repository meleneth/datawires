# frozen_string_literal: true

module EditForms
  class Binding
    class InvalidBindingError < ArgumentError; end
    class UnsupportedBindingKindError < ArgumentError; end

    attr_reader :data

    def initialize(data)
      @data = data
      raise InvalidBindingError, "binding must be an object" unless data.is_a?(Hash)
    end

    def kind
      data.fetch("kind")
    end

    def document_ptr
      raise UnsupportedBindingKindError, "unsupported binding kind: #{kind.inspect}" unless kind == "document_ptr"

      ptr = data.fetch("ptr")
      raise InvalidBindingError, "binding ptr must be a non-empty string" unless ptr.is_a?(String) && ptr.present?

      ptr
    end
  end
end
