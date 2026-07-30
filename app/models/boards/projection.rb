# frozen_string_literal: true

module Boards
  class Projection
    Entry = Data.define(:id, :kind, :title, :description, :config)

    attr_reader :title, :description, :layout, :sections, :actions

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
      @sections = project_entries(body.fetch("sections")).freeze
      @actions = project_entries(body.fetch("actions")).freeze
      freeze
    end

    private

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
