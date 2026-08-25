# frozen_string_literal: true

class AddArchivedAtToDomains < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :archived_at, :datetime
    add_index :domains, :archived_at
  end
end
