# frozen_string_literal: true

module Boards
  module Definitions
    BODY_WORKSPACE_PATH = Rails.root.join(
      "config/boards/datawires_body_workspace_v1.json"
    ).freeze
    WORLDBUILDER_WORKSPACE_PATH = Rails.root.join(
      "config/boards/worldbuilder_workspace_v1.json"
    ).freeze

    module_function

    def body_workspace
      @body_workspace ||= UuidTools.deep_freeze(
        JSON.parse(BODY_WORKSPACE_PATH.read)
      )
    end

    def worldbuilder_workspace
      @worldbuilder_workspace ||= UuidTools.deep_freeze(
        JSON.parse(WORLDBUILDER_WORKSPACE_PATH.read)
      )
    end
  end
end
