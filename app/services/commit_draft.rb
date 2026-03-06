class CommitDraft
  Result = Struct.new(:commit, :document, :redirect_path, keyword_init: true)

  def self.call(...)
    new(...).call
  end

  def initialize(draft:, message:)
    @draft = draft
    @message = message
  end

  def call
    ActiveRecord::Base.transaction do
      document = @draft.draftable
      parent_commit = document.head_commit

      commit = document.commits.create!(
        message: @message,
        author_name: Current.user&.name
      )

      commit.commit_parents.create!(parent: parent_commit) if parent_commit.present?

      snapshot = document.create_document_snapshot!(
        body: @draft.content,
        commit: commit
      )

      document.update!(
        head_commit: commit,
        document_snapshot: snapshot
      )

      @draft.destroy!

      Result.new(
        commit: commit,
        document: document,
        redirect_path: redirect_path_for(document)
      )
    end
  end

  private

  def redirect_path_for(document)
    Rails.application.routes.url_helpers.document_path(document)
  end
end
