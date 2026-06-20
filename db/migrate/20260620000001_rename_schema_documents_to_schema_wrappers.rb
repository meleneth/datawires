# frozen_string_literal: true

class RenameSchemaDocumentsToSchemaWrappers < ActiveRecord::Migration[8.1]
  def change
    rename_table :schema_documents, :schema_wrappers

    rename_column :edit_affordances, :for_schema_document_id, :schema_wrapper_id
    rename_column :view_affordances, :for_schema_document_id, :schema_wrapper_id

    rename_index :schema_wrappers,
      :index_schema_documents_on_document_id,
      :index_schema_wrappers_on_document_id if index_name_exists?(:schema_wrappers, :index_schema_documents_on_document_id)

    rename_index :edit_affordances,
      :index_edit_affordances_on_schema_and_title,
      :index_edit_affordances_on_schema_wrapper_and_title if index_name_exists?(:edit_affordances, :index_edit_affordances_on_schema_and_title)

    rename_index :view_affordances,
      :index_view_affordances_on_schema_and_title,
      :index_view_affordances_on_schema_wrapper_and_title if index_name_exists?(:view_affordances, :index_view_affordances_on_schema_and_title)
  end
end
