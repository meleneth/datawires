# frozen_string_literal: true

module JsonPtr
  # A token in JSON Pointer space must be representable in both:
  # - unescaped form (actual key: "a/b", "~")
  # - escaped form (pointer segment: "a~1b", "~0")
  #
  # Keep these distinct so we never "forget" which form we have.
  class Token
    def initialize(str)
      @str = String(str)
    end

    def unescaped
      raise NotImplementedError
    end

    def escaped
      raise NotImplementedError
    end

    def ==(other)
      other.is_a?(Token) && unescaped == other.unescaped
    end

    alias eql? ==

    def hash
      unescaped.hash
    end
  end

  class UnescapedToken < Token
    def unescaped = @str

    def escaped
      @str.gsub("~", "~0").gsub("/", "~1")
    end

    def to_s = unescaped
  end

  class EscapedToken < Token
    def escaped = @str

    def unescaped
      # Order matters: ~1 first, then ~0.
      @str.gsub("~1", "/").gsub("~0", "~")
    end

    def to_s = escaped
  end
end
