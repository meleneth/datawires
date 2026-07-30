# frozen_string_literal: true

module Boards
  module DomainCommands
    class Registry
      COMMANDS = {
        "create_body" => CreateBody,
        "create_meeting" => CreateMeeting,
        "submit_proposal" => SubmitProposal
      }.freeze

      def self.fetch(name, board:, actor:)
        command_class = COMMANDS[name.to_s]
        command_class&.new(board:, actor:)
      end
    end
  end
end
