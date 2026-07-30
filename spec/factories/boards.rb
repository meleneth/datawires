# frozen_string_literal: true

FactoryBot.define do
  factory :board do
    association :schema_wrapper
    sequence(:title) { |n| "Board #{n}" }

    board_document do
      board_schema = create(
        :document,
        :with_schema_head_revision,
        domain: schema_wrapper.domain,
        key: Boards::Schema::KEY,
        head_body: Boards::Schema::BODY
      )
      SchemaWrapper.create!(document: board_schema)
      create(
        :document,
        :with_head_revision,
        domain: schema_wrapper.domain,
        schema_document: board_schema,
        head_body: {
          "version" => 1,
          "title" => title,
          "description" => "",
          "layout" => { "columns" => 1 },
          "sections" => [],
          "actions" => []
        }
      )
    end
  end
end
