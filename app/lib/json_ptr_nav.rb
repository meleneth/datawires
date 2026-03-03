# frozen_string_literal: true

class JsonPtrNav
  DEFAULT_KEY_ORDER = JsonPtr::KeyOrder.new(
    priority: %w[$schema $id title description type properties $defs required]
  )

  def initialize(json, key_order: DEFAULT_KEY_ORDER)
    @json = json
    @key_order = key_order
  end

  def value_at(ptr)
    JsonPtr.get(@json, ptr)
  end

  def object_keys_at(ptr)
    val = value_at(ptr)
    return [] unless val.is_a?(Hash)

    keys = val.keys.map(&:to_s)

    # Your JsonPtr::KeyOrder already exists (spec covers priority behavior).
    # If it has a different API than `sort`, adjust here.
    if @key_order.respond_to?(:sort)
      @key_order.sort(keys)
    else
      # fallback: schema-friendly-ish, then lexicographic
      keys.sort
    end
  end

  def child_ptr(parent_ptr, child_key)
    JsonPtr::Pointer.parse(parent_ptr.to_s).child(child_key.to_s).to_s
  end
end
