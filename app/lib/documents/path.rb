# frozen_string_literal: true

module Documents
  class Path
    class InvalidPathError < ArgumentError; end

    ROOT = "".freeze

    attr_reader :document_ptr

    def initialize(document_ptr = ROOT)
      @document_ptr = normalize_ptr(document_ptr)
    end

    def self.root
      new(ROOT)
    end

    def root?
      document_ptr == ROOT
    end

    def pointer
      @pointer ||= JsonPtr::Pointer.parse(document_ptr)
    end

    def tokens
      pointer.tokens.map(&:unescaped)
    end

    def child(segment)
      self.class.new(pointer.child(segment.to_s).to_s)
    end

    def parent
      return nil if root?

      parent_tokens = tokens[0...-1]
      ptr = parent_tokens.reduce(JsonPtr::Pointer.parse(ROOT)) do |memo, token|
        memo.child(token)
      end

      self.class.new(ptr.to_s)
    end

    def name
      tokens.last
    end

    def to_s
      document_ptr
    end

    def schema_ptr
      return "" if root?

      parts = []

      tokens.each do |token|
        parts << "properties"
        parts << token
      end

      "/" + parts.join("/")
    end

    private

    def normalize_ptr(raw)
      JsonPtr::Pointer.parse(raw.nil? ? ROOT : raw).to_s
    rescue ArgumentError => e
      raise InvalidPathError, e.message
    end
  end
end
