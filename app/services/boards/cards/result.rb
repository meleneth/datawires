# frozen_string_literal: true

module Boards
  module Cards
    Result = Data.define(:status, :title, :description, :data, :href, :action_path, :action_method) do
      def available?
        status == "available"
      end
    end
  end
end
