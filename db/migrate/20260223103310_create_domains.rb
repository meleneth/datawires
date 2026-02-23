class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains, id: :uuid do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :domains, :slug
  end
end
