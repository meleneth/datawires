# frozen_string_literal: true

module Boards
  module Layouts
    class BaseProvider
      def self.validate(_config, path: "layout")
        []
      end
    end
  end
end
