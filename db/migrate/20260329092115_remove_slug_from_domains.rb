class RemoveSlugFromDomains < ActiveRecord::Migration[8.1]
  def change
    remove_column :domains, :slug, :string
  end
end
