# frozen_string_literal: true

module Seeds
  module DocumentSeedHelper
    module_function

    def ensure_domain!(name:)
      Domain.find_or_create_by!(name:)
    end

    def find_domain!(name:)
      Domain.find_by!(name:)
    end

    def find_document!(domain_name:, key:)
      domain = find_domain!(name: domain_name)
      Document.find_by!(domain:, key:)
    end

    def ensure_document_with_revision!(
      domain:,
      key:,
      body:,
      title: nil,
      schema_document: nil,
      message: "Seed document"
    )
      document = Document.find_or_initialize_by(domain:, key:)

      document.title = title if title.present?

      # Do not assign schema_document yet. For schema-backed validations,
      # the document may need its head_revision in place first.
      document.save! if document.new_record? || document.changed?

      current_body = document.head_revision&.body

      if current_body != body
        revision = document.revisions.create!(
          body:,
          parent_revision: document.head_revision,
          message:
        )

        document.update!(head_revision: revision)
      end

      if document.schema_document != schema_document
        document.update!(schema_document:)
      end

      document
    end
  end
end
