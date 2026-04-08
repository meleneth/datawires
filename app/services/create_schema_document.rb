# frozen_string_literal: true

class CreateSchemaDocument
  Result = Struct.new(:document, :draft)

  def self.call(domain:, key:, title: nil, actor: nil)
    new(domain:, key:, title:, actor:).call
  end

  def initialize(domain:, key:, title:, actor:)
    @domain = domain
    @key = key
    @title = title
    @actor = actor
  end

  def call
    Document.transaction do
      document = @domain.documents.create!(key: @key, title: @title)

      draft = document.drafts.create!(
        created_by: @actor,
        based_on_revision: document.head_revision,
        body: starter_body
      )

      Result.new(document, draft)
    end
  end

  private

  def starter_body
    {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => schema_id,
      "type" => "object",
      "properties" => {}
    }
  end

  def schema_id
    # JSON Schema $id is a stable identifier, not necessarily a resolvable URL.
    # In datawires, we derive it from the internal domain namespace and document key.
    "http://#{@domain.name}/schemas/#{@key}"
  end
end
