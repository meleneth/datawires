# frozen_string_literal: true

require_relative "json_ptr/token"
require_relative "json_ptr/pointer"
require_relative "json_ptr/key_order"
require_relative "json_ptr/access"
require_relative "json_ptr/enumeration"

module JsonPtr
  module_function

  UNDEFINED = Object.new.freeze

  def fetch(doc, pointer, default: UNDEFINED, access: Access.new)
    ptr = pointer.is_a?(Pointer) ? pointer : Pointer.parse(pointer)
    cur = doc

    ptr.tokens.each do |tok|
      token = tok.unescaped

      # Descend one step, but detect "missing" without confusing it with nil
      case cur
      when Hash
        # mirror Access policy: symbol-first, string fallback
        val = access.get(cur, token)
        if val.nil?
          # if neither key exists, this was missing
          sym = safe_to_sym_for_exist_check(token)
          return default unless cur.key?(token) || (sym && cur.key?(sym))
        end
        cur = val
      when Array
        idx = Integer(token, 10) rescue nil
        return default if idx.nil? || idx < 0 || idx >= cur.length
        cur = cur[idx]
      else
        return default
      end
    end

    cur
  end

  def get(doc, pointer, access: Access.new)
    fetch(doc, pointer, default: nil, access: access)
  end

  def exist?(doc, pointer, access: Access.new)
    fetch(doc, pointer, default: UNDEFINED, access: access) != UNDEFINED
  end

  def set(doc, pointer, value, access: Access.new)
    ptr = pointer.is_a?(Pointer) ? pointer : Pointer.parse(pointer)
    return value if ptr.root?

    tokens = ptr.tokens

    leaf_token = tokens.last.unescaped

    parent_ptr = Pointer.new(tokens[0...-1])

    parent_val = fetch(doc, parent_ptr, default: UNDEFINED, access: access)
    raise KeyError, "Parent path missing: #{parent_ptr}" if parent_val == UNDEFINED

    updated_parent = access.set(parent_val, leaf_token, value)
    set(doc, parent_ptr, updated_parent, access: access)
  end

  def each_pointer(doc, key_order: KeyOrder.new, &block)
    Enumeration.new(key_order: key_order).each_pointer(doc, &block)
  end

  # Internal: used only to mirror Access' symbol policy for existence checks.
  def safe_to_sym_for_exist_check(token)
    return nil unless token.is_a?(String)
    return nil if token.empty? || token.bytesize > 200
    return nil unless token.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*[!?=]?\z/)
    token.to_sym
  end

  private_class_method :safe_to_sym_for_exist_check
end
