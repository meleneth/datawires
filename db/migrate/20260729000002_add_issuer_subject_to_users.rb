# frozen_string_literal: true

class AddIssuerSubjectToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :identity_issuer, :string
    add_column :users, :identity_subject, :string

    add_index :users,
              %i[identity_issuer identity_subject],
              unique: true,
              where: "identity_issuer IS NOT NULL AND identity_subject IS NOT NULL",
              name: "index_users_on_identity_issuer_and_subject"
  end
end
