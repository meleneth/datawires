# frozen_string_literal: true

module EditAffordances
  class CellBinding
    class UnsupportedBindingKindError < ArgumentError; end

    attr_reader :binding

    def initialize(binding)
      @binding = binding || {}
    end

    def kind
      binding["kind"]
    end

    def document_ptr?
      kind == "document_ptr"
    end

    def ptr
      return binding["ptr"] if document_ptr?

      raise UnsupportedBindingKindError, "unsupported binding kind: #{kind.inspect}"
    end
  end
end
