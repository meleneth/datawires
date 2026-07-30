# frozen_string_literal: true

module ProceduralPolicies
  class MaterializeDocuments
    TYPES = {
      "decision" => Decisions::Schema,
      "agreement" => Agreements::Schema
    }.freeze

    def self.call(meeting:, actor:, outputs:)
      new(meeting:, actor:, outputs:).call
    end

    def initialize(meeting:, actor:, outputs:)
      @meeting = meeting
      @actor = actor
      @outputs = outputs
    end

    def call
      outputs.map { |output| materialize(output) }
    end

    private

    attr_reader :meeting, :actor, :outputs

    def materialize(output)
      schema = TYPES.fetch(output.fetch("type"))
      key = output.fetch("id")
      existing = meeting.body.domain.documents.find_by(key:)
      return verify_existing!(existing, output) if existing

      document = meeting.body.domain.documents.create!(
        key:,
        title: output.fetch("title"),
        schema_document: schema_document(schema)
      )
      revision = document.revisions.create!(
        body: output.fetch("body"),
        message: "Materialize #{output.fetch("type")} from Meeting #{meeting.id}",
        created_by: actor.user
      )
      document.update!(head_revision: revision)
      document
    end

    def verify_existing!(document, output)
      unless document.schema_document&.key == TYPES.fetch(output.fetch("type")).const_get(:KEY) &&
          document.body == output.fetch("body")
        raise ArgumentError, "policy document output id conflicts with existing content"
      end

      document
    end

    def schema_document(schema)
      existing = meeting.body.domain.documents.find_by(key: schema::KEY)
      return existing if existing&.body == schema::BODY
      raise ArgumentError, "policy output schema key conflicts with an existing document" if existing

      document = meeting.body.domain.documents.create!(key: schema::KEY, title: schema::BODY.fetch("title"))
      revision = document.revisions.create!(
        body: schema::BODY,
        message: "Create #{schema::BODY.fetch("title")} schema",
        created_by: actor.user
      )
      document.update!(head_revision: revision)
      SchemaWrapper.create!(document:)
      document
    end
  end
end
