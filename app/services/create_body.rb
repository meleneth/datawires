# frozen_string_literal: true

class CreateBody
  Result = Data.define(:body, :document, :draft)

  def self.call(domain:, name:, actor:)
    new(domain:, name:, actor:).call
  end

  def initialize(domain:, name:, actor:)
    raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)
    raise ArgumentError, "actor is required" unless actor

    @domain = domain
    @name = name.to_s.strip
    @actor = actor
  end

  def call
    ApplicationRecord.transaction do
      document = domain.documents.create!(
        key: next_key,
        title: name,
        schema_document: body_schema_document
      )
      revision = document.revisions.create!(
        body: { "name" => name },
        message: "Create body #{name}",
        created_by: actor
      )
      document.update!(head_revision: revision)
      body = Body.create!(body_document: document)
      Result.new(body:, document:, draft: document.draft_for(actor:))
    end
  end

  private

  attr_reader :domain, :name, :actor

  def next_key
    base = name.parameterize.presence || "body"
    return base unless domain.documents.exists?(key: base)

    index = 2
    index += 1 while domain.documents.exists?(key: "#{base}-#{index}")
    "#{base}-#{index}"
  end

  def body_schema_document
    existing = domain.documents.find_by(key: Bodies::Schema::KEY)
    return existing if existing&.body == Bodies::Schema::BODY
    raise ArgumentError, "body is not the Datawires Body schema" if existing

    document = domain.documents.create!(key: Bodies::Schema::KEY, title: Bodies::Schema::TITLE)
    revision = document.revisions.create!(
      body: Bodies::Schema::BODY,
      message: "Create Body schema",
      created_by: actor
    )
    document.update!(head_revision: revision)
    SchemaWrapper.create!(document:)
    document
  end
end
