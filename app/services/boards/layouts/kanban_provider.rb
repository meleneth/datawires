# frozen_string_literal: true

module Boards
  module Layouts
    class KanbanProvider < BaseProvider
      def self.container_class
        "flex items-start gap-4 overflow-x-auto pb-4"
      end

      def self.column_class
        "w-80 shrink-0"
      end
    end
  end
end
