# frozen_string_literal: true

class CreateProceduralPolicy
  def self.call(body:, name:, definition:, actor:)
    new(body:, name:, definition:, actor:).call
  end

  def initialize(body:, name:, definition:, actor:)
    @body = body
    @name = name
    @definition = definition
    @actor = actor
  end

  def call
    existing = body.procedural_policies.find_by(name:)
    return existing if existing&.policy_document&.body == definition
    raise ArgumentError, "procedural policy name already exists with different content" if existing

    ApplicationRecord.transaction do
      document = body.domain.documents.create!(
        key: next_key,
        title: name,
        schema_document: policy_schema_document
      )
      revision = document.revisions.create!(
        body: definition,
        message: "Create procedural policy #{name}",
        created_by: actor
      )
      document.update!(head_revision: revision)
      ProceduralPolicy.create!(body:, name:, policy_document: document)
    end
  end

  private

  attr_reader :body, :name, :definition, :actor

  def next_key
    base = "#{name.parameterize}-policy"
    return base unless body.domain.documents.exists?(key: base)

    "#{base}-#{SecureRandom.hex(3)}"
  end

  def policy_schema_document
    existing = body.domain.documents.find_by(key: ProceduralPolicies::Schema::KEY)
    return existing if existing&.body == ProceduralPolicies::Schema::BODY
    raise ArgumentError, "procedural-policy key is not the Datawires policy schema" if existing

    document = body.domain.documents.create!(key: ProceduralPolicies::Schema::KEY, title: "Procedural Policy")
    revision = document.revisions.create!(
      body: ProceduralPolicies::Schema::BODY,
      message: "Create Procedural Policy schema",
      created_by: actor
    )
    document.update!(head_revision: revision)
    SchemaWrapper.create!(document:)
    document
  end
end
