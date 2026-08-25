# frozen_string_literal: true

module Documents
  class ApplyKeyTemplates
    GENERATED_KEY = /\Adocument-[0-9a-f]{8}\z/

    def self.call(domain:)
      domain.documents.with_head.where.not(schema_document_id: nil).find_each.filter_map do |document|
        next unless GENERATED_KEY.match?(document.key.to_s)

        key = Documents::KeyTemplate.resolve(schema_document: document.schema_document, body: document.body)
        next if key.blank?

        document.update!(key: key)
        document
      rescue ArgumentError
        nil
      end
    end
  end
end
