# app/services/create_schema_document.rb
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
        based_on_revision: document.head_revision, # nil on brand new doc is fine
        body: starter_body,
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
      "properties" => {},
    }
  end

  def schema_id
    # Pick one canonical rule and keep it forever.
    # If domain.slug is not actually your host, swap it for whatever is.
    "http://#{@domain.slug}/schemas/#{@key}"
  end
end
