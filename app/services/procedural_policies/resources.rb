# frozen_string_literal: true

module ProceduralPolicies
  module Resources
    class NotFound < StandardError; end
    class UnknownType < StandardError; end

    DEFINITIONS = {
      "proposal" => {
        model: Proposal,
        attributes: {
          "id" => ->(proposal) { proposal.id },
          "body_id" => ->(proposal) { proposal.body_id },
          "submitted_revision_id" => ->(proposal) { proposal.submitted_revision_id },
          "submitted_content" => ->(proposal) { proposal.submitted_revision.body.fetch("content") },
          "title" => ->(proposal) { proposal.proposal_document.title }
        }.freeze
      }.freeze
    }.freeze

    module_function

    def resolve(type:, id:)
      definition = DEFINITIONS[type] || raise(UnknownType, "Policy resource type is not registered.")
      record = definition.fetch(:model).find_by(id:) || raise(NotFound, "#{type.humanize} was not found.")
      UuidTools.deep_freeze(
        definition.fetch(:attributes).transform_values { |project| project.call(record).deep_dup }
      )
    end

    def types
      DEFINITIONS.keys
    end

    def attributes_for(type)
      DEFINITIONS.fetch(type).fetch(:attributes).keys
    end
  end
end
