# frozen_string_literal: true

class EnsureDraftForDocument
  def self.call(document:, actor:)
    new(document:, actor:).call
  end

  def initialize(document:, actor:)
    raise ArgumentError, "actor is required" unless actor

    @document = document
    @actor = actor
  end

  def call
    existing_draft || create_draft!
  end

  private

  def existing_draft
    @document.drafts.find_by(created_by: @actor)
  end

  def create_draft!
    @document.drafts.create!(
      created_by: @actor,
      based_on_revision: @document.head_revision,
      body: starting_body,
    )
  end

  def starting_body
    @document.head_revision&.body || {}
  end
end
