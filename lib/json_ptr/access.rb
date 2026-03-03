# frozen_string_literal: true

module JsonPtr
  class Access
    def initialize(symbol_first: true)
      @symbol_first = symbol_first
    end

    def get(container, token_unescaped)
      case container
      when Hash
        get_hash(container, token_unescaped)
      when Array
        idx = Integer(token_unescaped, 10) rescue nil
        return nil if idx.nil?
        container[idx]
      else
        nil
      end
    end

    def set(container, token_unescaped, value)
      case container
      when Hash
        set_hash(container, token_unescaped, value)
      when Array
        idx = Integer(token_unescaped, 10)
        dup = container.dup
        dup[idx] = value
        dup
      else
        raise TypeError, "Cannot set into #{container.class}"
      end
    end

    private

    def get_hash(h, token)
      # Prefer symbol lookup if token looks symbol-able.
      if @symbol_first
        sym = safe_to_sym(token)
        if sym && h.key?(sym)
          return h[sym]
        end
      end

      # String fallback.
      return h[token] if h.key?(token)

      # If symbol_first was off, still allow symbol fallback secondarily.
      if !@symbol_first
        sym = safe_to_sym(token)
        return h[sym] if sym && h.key?(sym)
      end

      nil
    end

    def set_hash(h, token, value)
      dup = h.dup
      if @symbol_first
        sym = safe_to_sym(token)
        if sym && dup.key?(sym)
          dup[sym] = value
          return dup
        end
      end

      if dup.key?(token)
        dup[token] = value
        return dup
      end

      # If neither existed, choose a default key form (Ruby-ish: symbol if safe)
      sym = safe_to_sym(token)
      dup[sym || token] = value
      dup
    end

    def safe_to_sym(token)
      # Avoid symbolizing arbitrary garbage (memory leak / DOS).
      # Make this stricter if you want.
      return nil if token.empty?
      return nil if token.bytesize > 200
      return nil unless token.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*[!?=]?\z/)
      token.to_sym
    end
  end
end
