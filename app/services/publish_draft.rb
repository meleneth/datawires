# frozen_string_literal: true

class PublishDraft
  class StaleDraftError < StandardError; end

  def self.call(draft:, message:, actor: nil)
    new(draft:, message:, actor:).call
  end

  def initialize(draft:, message:, actor:)
    raise ArgumentError, "draft must be a Draft" unless draft.is_a?(Draft)

    @draft = draft
    @document = draft.document
    @message = message
    @actor = actor || draft.created_by
  end

  def call
    revision = ApplicationRecord.transaction do
      @draft.lock!
      @document.lock!
      @document.reload

      ensure_not_stale!

      revision = Revision.create!(
        document: @document,
        parent_revision: base_revision,
        body: deep_dup_json(@draft.body),
        message: @message,
        created_by: @actor
      )

      @document.update!(head_revision: revision)
      SyncSchemaWrapperForDocument.call(document: @document)
      @draft.destroy!

      revision
    end
    DocumentIndexes::RebuildJob.perform_later(@document.id, revision.id)
    revision
  end

  private

  def base_revision
    @draft.based_on_revision || @document.head_revision
  end

  def ensure_not_stale!
    return if @draft.based_on_revision.nil?
    return if @draft.based_on_revision == @document.head_revision

    raise StaleDraftError,
      "Draft is stale: based_on_revision=#{@draft.based_on_revision_id} head_revision=#{@document.head_revision_id}"
  end

  def deep_dup_json(value)
    Marshal.load(Marshal.dump(value))
  end
end
