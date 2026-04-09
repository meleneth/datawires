module Documents
  # app/lib/document_seed_value.rb
  class SeedValue
    def self.for(schema_node)
      case schema_node["type"]
      when "object"
        {}
      when "array"
        []
      when "string"
        ""
      when "integer"
        0
      when "number"
        0
      when "boolean"
        false
      else
        nil
      end
    end
  end
end
