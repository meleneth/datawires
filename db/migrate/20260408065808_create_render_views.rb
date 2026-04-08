# frozen_string_literal: true

class CreateRenderViews < ActiveRecord::Migration[8.1]
  def change
    create_table :render_views, id: :uuid do |t|
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

      t.string :name, null: false

      t.timestamps
    end

    add_index :render_views,
      [ :for_schema_document_id, :name ],
      unique: true,
      name: "index_render_views_on_schema_and_name"

    add_index :render_views,
      :view_document_id,
      unique: true
  end
end
