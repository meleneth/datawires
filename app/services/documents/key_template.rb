# frozen_string_literal: true

module Documents
  class KeyTemplate
    METADATA_KEY = "x-datawires-document-key"
    TOKEN = /#\{([^}]+)\}/

    def self.resolve(schema_document:, body:)
      template = schema_document&.body&.[](METADATA_KEY)
      return if template.blank?

      template.gsub(TOKEN) do
        path = Regexp.last_match(1)
        value = path.split(".").reduce(body) do |current, segment|
          current.is_a?(Hash) ? current[segment] : nil
        end
        raise ArgumentError, "document key template value #{path.inspect} is missing" if value.blank?

        value.to_s
      end
    end
  end
end
