module Documents
  # app/lib/document_path.rb
  # frozen_string_literal: true

  class Path
    ROOT = "".freeze

    def self.normalize(raw)
      JsonPtr::Pointer.parse(raw.presence || ROOT).to_s
    rescue ArgumentError
      ROOT
    end

    def initialize(path = ROOT)
      @path = self.class.normalize(path)
    end

    def to_s
      @path
    end

    def document_ptr
      @path
    end

    def root?
      tokens.empty?
    end

    def tokens
      JsonPtr::Pointer.parse(@path).tokens.map(&:unescaped)
    end

    def child(token)
      ptr = JsonPtr::Pointer.parse(@path)
      self.class.new(ptr.child(token.to_s).to_s)
    end

    def parent
      self.class.new(JsonPtr::Pointer.parse(@path).parent.to_s)
    end

    # Maps document path → schema path
    # e.g.
    # ""                -> ""
    # "/foo"            -> "/properties/foo"
    # "/foo/bar"        -> "/properties/foo/properties/bar"
    def schema_ptr
      ptr = JsonPtr::Pointer.parse(ROOT)

      tokens.each do |tok|
        ptr = ptr.child("properties").child(tok)
      end

      ptr.to_s
    end

    # Convenience for "what children exist here?"
    # e.g. "/foo" -> "/properties/foo/properties"
    def schema_properties_ptr
      JsonPtr::Pointer.parse(schema_ptr).child("properties").to_s
    end
  end
end
