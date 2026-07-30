# frozen_string_literal: true

class CreateBoard
  Result = Data.define(:board, :document, :draft)

  def self.call(schema_wrapper:, title:, actor:)
    new(schema_wrapper:, title:, actor:).call
  end

  def initialize(schema_wrapper:, title:, actor:)
    raise ArgumentError, "schema_wrapper must be a SchemaWrapper" unless schema_wrapper.is_a?(SchemaWrapper)
    raise ArgumentError, "actor is required" unless actor

    @schema_wrapper = schema_wrapper
    @title = title.presence || "Datawires Board"
    @actor = actor
  end

  def call
    ApplicationRecord.transaction do
      document = schema_wrapper.domain.documents.create!(
        key: next_key,
        title: "#{schema_wrapper.key} #{title}",
        schema_document: board_schema_document
      )
      revision = document.revisions.create!(
        body: initial_body,
        message: "Create board #{title}",
        created_by: actor
      )
      document.update!(head_revision: revision)

      board = schema_wrapper.boards.create!(title: unique_title, board_document: document)
      schema_wrapper.update!(default_board: board) if schema_wrapper.default_board_id.blank?

      Result.new(board:, document:, draft: document.draft_for(actor:))
    end
  end

  private

  attr_reader :schema_wrapper, :title, :actor

  def unique_title
    return title unless schema_wrapper.boards.exists?(title:)

    index = 2
    index += 1 while schema_wrapper.boards.exists?(title: "#{title} #{index}")
    "#{title} #{index}"
  end

  def next_key
    base = "#{schema_wrapper.key}-board"
    return base unless schema_wrapper.domain.documents.exists?(key: base)

    index = 2
    index += 1 while schema_wrapper.domain.documents.exists?(key: "#{base}-#{index}")
    "#{base}-#{index}"
  end

  def initial_body
    {
      "version" => 1,
      "title" => title,
      "description" => "",
      "layout" => { "columns" => 1 },
      "sections" => [],
      "actions" => []
    }
  end

  def board_schema_document
    @board_schema_document ||= begin
      existing = schema_wrapper.domain.documents.find_by(key: Boards::Schema::KEY)
      if existing
        raise ArgumentError, "#{Boards::Schema::KEY} is not the Datawires Board schema" unless existing.body == Boards::Schema::BODY

        existing
      else
        document = schema_wrapper.domain.documents.create!(
          key: Boards::Schema::KEY,
          title: Boards::Schema::TITLE
        )
        revision = document.revisions.create!(
          body: Boards::Schema::BODY,
          message: "Create Datawires Board schema",
          created_by: actor
        )
        document.update!(head_revision: revision)
        SchemaWrapper.create!(document:)
        document
      end
    end
  end
end
