module Schemas
  # app/lib/schema_path.rb
  # frozen_string_literal: true

  class Path
    ROOT = "/".freeze

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
      return self.class.new(ROOT) if root?

      toks = tokens[0...-1]
      return self.class.new(ROOT) if toks.empty?

      ptr = JsonPtr::Pointer.parse(ROOT)
      toks.each { |tok| ptr = ptr.child(tok) }
      self.class.new(ptr.to_s)
    end

    def json_ptr
      ptr = JsonPtr::Pointer.parse(ROOT)
      tokens.each do |tok|
        ptr = ptr.child("properties").child(tok)
      end
      ptr.to_s
    end

    def properties_ptr
      ptr = JsonPtr::Pointer.parse(json_ptr)
      ptr.child("properties").to_s
    end
  end
end
