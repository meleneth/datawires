# frozen_string_literal: true

module Boards
  class Projection
    Entry = Data.define(:id, :kind, :title, :description, :config)
    Card = Data.define(:id, :kind, :title, :description, :config)
    Column = Data.define(:id, :title, :cards)

    attr_reader :title, :description, :layout, :layout_provider, :columns, :sections, :actions

    def self.build(board)
      raise ArgumentError, "board must be a Board" unless board.is_a?(Board)

      validator = BodyValidator.new(board.body)
      raise ArgumentError, validator.errors.to_sentence unless validator.valid?

      new(board.body)
    end

    def initialize(body)
      @title = body.fetch("title")
      @description = body["description"].to_s
      @layout = body.fetch("layout", {}).deep_dup.freeze
      @layout_provider = @layout.fetch("provider", "kanban")
      @columns = project_columns(body.fetch("columns", [])).freeze
      @sections = project_entries(body.fetch("sections")).freeze
      @actions = project_entries(body.fetch("actions")).freeze
      freeze
    end

    private

    def project_columns(columns)
      columns.map do |column|
        Column.new(
          id: column.fetch("id"),
          title: column.fetch("title"),
          cards: Array(column["cards"]).map do |card|
            Card.new(id: card.fetch("id"), kind: card.fetch("kind"), title: card.fetch("title"),
              description: card["description"].to_s, config: card.fetch("config", {}).deep_dup.freeze)
          end.freeze
        )
      end
    end

    def project_entries(entries)
      entries.map do |entry|
        Entry.new(
          id: entry.fetch("id"),
          kind: entry.fetch("kind"),
          title: entry.fetch("title"),
          description: entry["description"].to_s,
          config: entry.fetch("config", {}).deep_dup.freeze
        )
      end
    end
  end
end
