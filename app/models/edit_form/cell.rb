# frozen_string_literal: true

module EditForms
  class Cell
    class InvalidCellError < ArgumentError; end

    attr_reader :data

    def initialize(data)
      @data = data
      raise InvalidCellError, "cell must be an object" unless data.is_a?(Hash)
    end

    def commit?
      data["kind"] == "commit"
    end

    def field?
      data.key?("binding")
    end

    def binding
      return nil unless field?

      @binding ||= EditForms::Binding.new(data.fetch("binding"))
    end

    def span
      data["span"]
    end

    def widget
      data["widget"]
    end

    def label
      data["label"]
    end
  end
end
