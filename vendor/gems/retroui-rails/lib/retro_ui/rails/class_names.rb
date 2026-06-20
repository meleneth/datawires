# frozen_string_literal: true

module RetroUI
  module Rails
    module ClassNames
      module_function

      # Small class-list helper for the first gem slice.
      #
      # This intentionally does not implement Tailwind-aware conflict resolution
      # like tailwind-merge. It only flattens values and joins truthy class
      # strings, keeping the call sites easy to swap to a real merge strategy.
      def class_names(*values)
        values.flatten.compact.reject { |value| value == false }.map(&:to_s).reject(&:empty?).join(" ")
      end

      alias tw_merge class_names
    end
  end
end
