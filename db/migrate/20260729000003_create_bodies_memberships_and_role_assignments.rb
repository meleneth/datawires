# frozen_string_literal: true

class CreateBodiesMembershipsAndRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :bodies, id: :uuid do |t|
      t.references :body_document, null: false, type: :uuid, foreign_key: { to_table: :documents }, index: { unique: true }
      t.timestamps
    end

    create_table :memberships, id: :uuid do |t|
      t.references :body, null: false, type: :uuid, foreign_key: true
      t.references :actor, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "active"
      t.datetime :effective_from, null: false
      t.datetime :effective_until
      t.jsonb :provenance, null: false, default: {}
      t.references :recorded_by, type: :uuid, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :memberships, %i[body_id actor_id effective_from], name: "index_memberships_on_body_actor_effective_from"

    create_table :role_assignments, id: :uuid do |t|
      t.references :actor, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :role, null: false
      t.string :scope_type, null: false
      t.uuid :scope_id, null: false
      t.datetime :effective_from, null: false
      t.datetime :effective_until
      t.jsonb :provenance, null: false, default: {}
      t.references :recorded_by, type: :uuid, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :role_assignments,
              %i[scope_type scope_id actor_id role effective_from],
              name: "index_role_assignments_on_scope_actor_role_from"
  end
end
