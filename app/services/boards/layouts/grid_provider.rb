# frozen_string_literal: true

module Boards
  module Layouts
    class GridProvider < BaseProvider
      def self.container_class
        "grid gap-4 lg:grid-cols-3"
      end

      def self.column_class
        "min-w-0"
      end
    end
  end
end
