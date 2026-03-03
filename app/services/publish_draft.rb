# frozen_string_literal: true

class PublishDraft
  class StaleDraftError < StandardError; end

  # Publishes a Draft into an immutable Revision and advances Document#head_revision.
  #
  # Objects in, objects out:
  #   PublishDraft.call(draft:, message: nil, actor: nil) -> Revision
  #
  def self.call(draft:, message: nil, actor: nil)
    new(draft:, message:, actor:).call
  end

  def initialize(draft:, message:, actor:)
    raise ArgumentError, "draft must be a Draft" unless draft.is_a?(Draft)

    @draft = draft
    @document = draft.document
    @message = message
    @actor = actor
  end

  def call
    Draft.transaction do
      @draft.lock!
      @document.lock!

      ensure_not_stale!

      parent = base_revision

      revision = Revision.create!(
        document: @document,
        parent_revision: parent,
        body: deep_dup_hash(@draft.body),
        message: @message,
        created_by: @actor
      )

      @document.update!(head_revision: revision)

      # Keep the draft around for continued editing:
      # it now represents "working copy based on the new head".
      @draft.update!(
        based_on_revision: revision,
        body: deep_dup_hash(revision.body)
      )

      revision
    end
  end

  private

  def base_revision
    # The revision this draft was made against.
    @draft.based_on_revision || @document.head_revision
  end

  def ensure_not_stale!
    # If the draft claims it was based on something, require that it matches current head.
    # Since we don't do merges, publishing a stale draft is an error.
    return if @draft.based_on_revision.nil?

    if @draft.based_on_revision != @document.head_revision
      raise StaleDraftError,
            "Draft is stale: based_on_revision=#{@draft.based_on_revision_id} head_revision=#{@document.head_revision_id}"
    end
  end

  def deep_dup_hash(hash)
    # Ensure we never accidentally share mutable object graphs between draft/revision.
    Marshal.load(Marshal.dump(hash))
  end
end
