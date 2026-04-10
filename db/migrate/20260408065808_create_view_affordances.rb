# frozen_string_literal: true

class CreateViewAffordances < ActiveRecord::Migration[8.1]
  def change
    create_table :view_affordances, id: :uuid do |t|
      t.references :for_schema_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :documents },
        index: false

      t.references :view_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :documents },
        index: false

      t.string :title, null: false

      t.timestamps
    end

    add_index :view_affordances,
      [ :for_schema_document_id, :title ],
      unique: true,
      name: "index_view_affordances_on_schema_and_title"

    add_index :view_affordances,
      :view_document_id,
      unique: true
  end
end
