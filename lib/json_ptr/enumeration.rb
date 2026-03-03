# frozen_string_literal: true

module JsonPtr
  class Enumeration
    def initialize(key_order: KeyOrder.new)
      @key_order = key_order
    end

    # Depth-first, stable, sorted.
    # Yields [Pointer, value]
    def each_pointer(obj, base: Pointer.new([]), &block)
      return enum_for(:each_pointer, obj, base: base) unless block

      yield base, obj

      case obj
      when Hash
        keys = @key_order.sort_keys(obj.keys)
        keys.each do |k|
          yield_from_child(obj[k], base, k, &block)
        end
      when Array
        obj.each_with_index do |v, i|
          yield_from_child(v, base, i.to_s, &block)
        end
      end
    end

    private

    def yield_from_child(value, base, child_token_unescaped, &block)
      child_ptr = base.child(child_token_unescaped.to_s)
      each_pointer(value, base: child_ptr, &block)
    end
  end
end
