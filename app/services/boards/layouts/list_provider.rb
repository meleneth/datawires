# frozen_string_literal: true

module Boards
  module Layouts
    class ListProvider < BaseProvider
      def self.container_class
        "grid gap-4"
      end

      def self.column_class
        "min-w-0"
      end
    end
  end
end
