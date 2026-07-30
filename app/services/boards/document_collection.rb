# frozen_string_literal: true

module Boards
  class DocumentCollection
    Result = Data.define(:documents, :view_affordance, :empty_state, :error)

    def self.call(board:, section:)
      new(board:, section:).call
    end

    def initialize(board:, section:)
      raise ArgumentError, "board must be a Board" unless board.is_a?(Board)
      raise ArgumentError, "section must be a Boards::Projection::Entry" unless section.is_a?(Boards::Projection::Entry)

      @board = board
      @section = section
    end

    def call
      schema_wrapper = target_schema_wrapper
      return failure("Schema #{config.fetch("schema_key")} was not found.") unless schema_wrapper

      documents = schema_wrapper.conforming_documents.includes(:head_revision).to_a
      documents.select! { |document| matches_filters?(document) }
      documents.sort_by! { |document| sortable_value(document) }
      documents.reverse! if order.fetch("direction", "asc") == "desc"
      documents = documents.first(config.fetch("limit", 20))

      view_affordance = selected_view_affordance(schema_wrapper)
      if config.fetch("navigation", "document") == "view_affordance" && view_affordance.nil?
        return failure("View affordance #{config["view_affordance"]} was not found.")
      end

      Result.new(documents:, view_affordance:, empty_state:, error: nil)
    end

    private

    attr_reader :board, :section

    def config
      section.config
    end

    def target_schema_wrapper
      schema_document = board.schema_wrapper.domain.documents.find_by(key: config.fetch("schema_key"))
      schema_document&.schema_wrapper
    end

    def matches_filters?(document)
      Array(config["filters"]).all? do |filter|
        value_at(document.body, filter.fetch("path")) == filter["value"]
      end
    end

    def sortable_value(document)
      value = case order.fetch("by", "title")
      when "title" then document.title
      when "key" then document.key
      when "created_at" then document.created_at
      when "updated_at" then document.updated_at
      when "body" then value_at(document.body, order.fetch("path"))
      end

      [ value.nil? ? 1 : 0, value.to_s, document.id ]
    end

    def order
      config.fetch("order", {})
    end

    def value_at(body, pointer)
      JsonPtr::Pointer.parse(pointer).tokens.reduce(body) do |value, token|
        JsonPtr::Access.new(symbol_first: false).get(value, token.to_s)
      end
    end

    def selected_view_affordance(schema_wrapper)
      return nil unless config["view_affordance"].present?

      schema_wrapper.view_affordances.find_by(title: config["view_affordance"])
    end

    def empty_state
      config["empty_state"].presence || "No documents found."
    end

    def failure(message)
      Result.new(documents: [], view_affordance: nil, empty_state:, error: message)
    end
  end
end
