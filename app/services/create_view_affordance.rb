# frozen_string_literal: true

class CreateViewAffordance
  Result = Struct.new(:view_affordance, :document, :draft, keyword_init: true)

  def self.call(schema_wrapper:, title:, actor:)
    new(schema_wrapper:, title:, actor:).call
  end

  def initialize(schema_wrapper:, title:, actor:)
    raise ArgumentError, "schema_wrapper must be a SchemaWrapper" unless schema_wrapper.is_a?(SchemaWrapper)
    raise ArgumentError, "actor is required" unless actor

    @schema_wrapper = schema_wrapper
    @title = title.presence || "Default"
    @actor = actor
  end

  def call
    ApplicationRecord.transaction do
      document = @schema_wrapper.domain.documents.create!(
        key: next_key,
        title: "#{@schema_wrapper.key} #{@title} view affordance"
      )
      revision = document.revisions.create!(
        body: initial_body,
        message: "Create view affordance #{@title}",
        created_by: @actor
      )
      document.update!(head_revision: revision)

      view_affordance = @schema_wrapper.view_affordances.create!(
        title: unique_title,
        view_document: document
      )
      draft = document.draft_for(actor: @actor)

      Result.new(view_affordance:, document:, draft:)
    end
  end

  private

  def unique_title
    base = @title
    return base unless @schema_wrapper.view_affordances.exists?(title: base)

    index = 2
    loop do
      candidate = "#{base} #{index}"
      return candidate unless @schema_wrapper.view_affordances.exists?(title: candidate)

      index += 1
    end
  end

  def next_key
    base = "#{@schema_wrapper.key}-view-affordance"
    return base unless @schema_wrapper.domain.documents.exists?(key: base)

    index = 2
    loop do
      candidate = "#{base}-#{index}"
      return candidate unless @schema_wrapper.domain.documents.exists?(key: candidate)

      index += 1
    end
  end

  def initial_body
    {
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => @title,
      "config" => {
        "schema_key" => @schema_wrapper.key,
        "relative_time_label" => "Relative time"
      }
    }
  end
end
