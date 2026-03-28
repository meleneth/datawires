# app/components/document_scalar_field_component.rb
# frozen_string_literal: true

class DocumentScalarFieldComponent < ApplicationComponent
  def initialize(row:)
    @row = row
  end

  private

  attr_reader :row

  def field_id
    "value_#{row.ptr.to_s.gsub(/[^a-zA-Z0-9]+/, "_")}"
  end
end
