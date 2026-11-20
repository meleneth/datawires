# frozen_string_literal: true

module ViewAffordances
  class RelatedDocumentsProjection
    def self.call(document:, view_affordance:)
      config = view_affordance.body.fetch("config")
      schema = document.domain.documents.find_by(key: config.fetch("schema_key"))
      documents = if schema&.schema_wrapper
        schema.schema_wrapper.conforming_documents.includes(:head_revision).to_a
      else
        []
      end
      related = documents.select { |candidate| candidate.body[config.fetch("foreign_key")] == document.key }
      group_by = config["group_by"]
      groups = Array(config["groups"])
      grouped = if group_by.present?
        ordered = groups.each_with_object({}) { |value, hash| hash[value] = [] }
        related.each { |candidate| (ordered[candidate.body[group_by].to_s] ||= []) << candidate }
        ordered
      else
        { "All" => related }
      end

      Projection.new(
        renderer: "related_documents",
        title: view_affordance.body.fetch("title"),
        data: {
          "groups" => grouped,
          "create_label" => config["create_label"].presence || "Create",
          "schema_found" => schema&.schema_wrapper.present?,
          "schema_key" => config.fetch("schema_key")
        }
      )
    end
  end
end
