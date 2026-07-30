# frozen_string_literal: true

module Boards
  class MembershipCollection
    Row = Data.define(:label, :details)
    Result = Data.define(:rows, :empty_state, :error)

    def self.call(board:, section:, actor:)
      new(board:, section:, actor:).call
    end

    def initialize(board:, section:, actor:)
      @board = board
      @section = section
      @actor = actor
    end

    def call
      rows = Membership
        .includes(:actor, body: :body_document)
        .where(body: administrable_bodies)
        .order(effective_from: :desc)
        .limit(config.fetch("limit", 100))
        .map do |membership|
          Row.new(
            label: actor_label(membership.actor),
            details: [
              membership.body.body_document.title,
              membership.status.humanize,
              effective_range(membership)
            ]
          )
        end
      Result.new(rows:, empty_state: config["empty_state"].presence || "No memberships found.", error: nil)
    end

    private

    attr_reader :board, :section, :actor

    def config
      section.config
    end

    def administrable_bodies
      domain_bodies.select do |body|
        Authorization::Policy.call(actor:, action: :administer_board, resource: { body: }).allowed?
      end
    end

    def domain_bodies
      Body.where(body_document: board.schema_wrapper.domain.documents)
    end

    def actor_label(user)
      user.name.presence || user.email.presence || user.external_id.presence || user.identity_subject
    end

    def effective_range(record)
      ending = record.effective_until&.to_fs(:long) || "present"
      "#{record.effective_from.to_fs(:long)} – #{ending}"
    end
  end
end
