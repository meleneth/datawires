# frozen_string_literal: true

module JsonPtr
  class Pointer
    ROOT = "".freeze

    def self.parse(str)
      s = (str || "").to_s
      return new([]) if s.empty? || s == "/"
      raise ArgumentError, "JSON Pointer must start with '/'" unless s.start_with?("/")

      segments = s.split("/")[1..]
      tokens = segments.map { |seg| UnescapedToken.new(EscapedToken.new(seg).unescaped) }
      new(tokens)
    end

    def self.from_unescaped(tokens)
      new(tokens.map { |t| UnescapedToken.new(t) })
    end

    def initialize(tokens)
      @tokens = tokens.freeze
    end

    def tokens
      @tokens.dup
    end

    # Canonical JSON Pointer string (escaped segments)
    def to_s
      return ROOT if @tokens.empty?
      "/" + @tokens.map(&:escaped).join("/")
    end

    def root?
      @tokens.empty?
    end

    def child(token_unescaped)
      self.class.new(@tokens + [UnescapedToken.new(token_unescaped)])
    end

    def parent
      return self if root?
      self.class.new(@tokens[0...-1])
    end
  end
end
