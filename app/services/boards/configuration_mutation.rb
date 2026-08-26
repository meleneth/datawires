# frozen_string_literal: true

module Boards
  class ConfigurationMutation
    def self.call(board:, actor:, message:)
      body = board.body.deep_dup
      yield body
      errors = Boards::BodyValidator.new(body).errors
      raise ArgumentError, errors.to_sentence if errors.any?

      revision = board.board_document.revisions.create!(body:, parent_revision: board.head_revision, created_by: actor, message:)
      board.board_document.update!(head_revision: revision)
      revision
    end
  end
end
