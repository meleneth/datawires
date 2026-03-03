class AddHeadRevisionToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :documents,
                  :head_revision,
                  type: :uuid,
                  null: true,
                  foreign_key: { to_table: :revisions }
  end
end
