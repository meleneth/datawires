# frozen_string_literal: true

class AddPublicFlagsToSchemaAndAffordances < ActiveRecord::Migration[8.1]
  def change
    add_column :schema_wrappers, :public, :boolean, null: false, default: false
    add_column :edit_affordances, :public, :boolean, null: false, default: false
    add_column :view_affordances, :public, :boolean, null: false, default: false
  end
end
