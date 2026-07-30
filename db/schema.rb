# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_29_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "boards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "board_document_id", null: false
    t.datetime "created_at", null: false
    t.boolean "public", default: false, null: false
    t.uuid "schema_wrapper_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["board_document_id"], name: "index_boards_on_board_document_id", unique: true
    t.index ["schema_wrapper_id", "title"], name: "index_boards_on_schema_wrapper_id_and_title", unique: true
    t.index ["schema_wrapper_id"], name: "index_boards_on_schema_wrapper_id"
  end

  create_table "bodies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "body_document_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["body_document_id"], name: "index_bodies_on_body_document_id", unique: true
  end

  create_table "document_index_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "document_id", null: false
    t.string "index_type", null: false
    t.string "key"
    t.string "label"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "revision_id", null: false
    t.uuid "schema_document_id", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["document_id", "revision_id", "index_type", "key"], name: "index_document_index_entries_for_rebuild"
    t.index ["document_id"], name: "index_document_index_entries_on_document_id"
    t.index ["revision_id"], name: "index_document_index_entries_on_revision_id"
    t.index ["schema_document_id", "index_type", "label"], name: "index_document_index_entries_on_schema_type_label"
    t.index ["schema_document_id", "index_type", "value"], name: "index_document_index_entries_on_schema_type_value"
    t.index ["schema_document_id", "index_type"], name: "index_document_index_entries_on_schema_and_type"
    t.index ["schema_document_id"], name: "index_document_index_entries_on_schema_document_id"
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "domain_id", null: false
    t.uuid "head_revision_id"
    t.string "key"
    t.uuid "schema_document_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["domain_id", "key"], name: "index_documents_on_domain_id_and_key", unique: true
    t.index ["domain_id"], name: "index_documents_on_domain_id"
    t.index ["head_revision_id"], name: "index_documents_on_head_revision_id"
    t.index ["schema_document_id"], name: "index_documents_on_schema_document_id"
  end

  create_table "domain_commit_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "document_id", null: false
    t.string "document_key"
    t.uuid "domain_commit_id", null: false
    t.string "revision_hash", null: false
    t.uuid "revision_id", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "revision_id"], name: "index_domain_commit_documents_on_document_id_and_revision_id"
    t.index ["document_id"], name: "index_domain_commit_documents_on_document_id"
    t.index ["domain_commit_id", "document_id"], name: "idx_on_domain_commit_id_document_id_f784c1ed79", unique: true
    t.index ["domain_commit_id"], name: "index_domain_commit_documents_on_domain_commit_id"
    t.index ["revision_id"], name: "index_domain_commit_documents_on_revision_id"
  end

  create_table "domain_commits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.uuid "domain_id", null: false
    t.text "message"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "parent_domain_commit_id"
    t.string "state_hash", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_domain_commits_on_created_by_id"
    t.index ["domain_id", "state_hash"], name: "index_domain_commits_on_domain_id_and_state_hash", unique: true
    t.index ["domain_id"], name: "index_domain_commits_on_domain_id"
    t.index ["parent_domain_commit_id"], name: "index_domain_commits_on_parent_domain_commit_id"
  end

  create_table "domains", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "head_domain_commit_id"
    t.string "name", null: false
    t.uuid "owner_id"
    t.boolean "public", default: false, null: false
    t.boolean "repository_mode", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["head_domain_commit_id"], name: "index_domains_on_head_domain_commit_id"
    t.index ["name"], name: "index_domains_on_name", unique: true
    t.index ["owner_id", "public"], name: "index_domains_on_owner_id_and_public"
    t.index ["owner_id"], name: "index_domains_on_owner_id"
    t.index ["public"], name: "index_domains_on_public"
  end

  create_table "drafts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "based_on_revision_id"
    t.jsonb "body", default: {}, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.uuid "document_id", null: false
    t.datetime "updated_at", null: false
    t.index ["based_on_revision_id"], name: "index_drafts_on_based_on_revision_id"
    t.index ["created_by_id"], name: "index_drafts_on_created_by_id"
    t.index ["document_id", "created_by_id"], name: "index_drafts_on_document_id_and_created_by_id", unique: true
    t.index ["document_id"], name: "index_drafts_on_document_id"
  end

  create_table "edit_affordances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "edit_document_id", null: false
    t.boolean "public", default: false, null: false
    t.uuid "schema_wrapper_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["edit_document_id"], name: "index_edit_affordances_on_edit_document_id"
    t.index ["schema_wrapper_id", "title"], name: "index_edit_affordances_on_schema_wrapper_and_title", unique: true
  end

  create_table "event_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "actor_id"
    t.uuid "causation_id"
    t.uuid "command_id", null: false
    t.string "command_type", null: false
    t.integer "command_version", null: false
    t.uuid "correlation_id"
    t.datetime "created_at", null: false
    t.uuid "event_stream_id", null: false
    t.string "event_type", null: false
    t.integer "event_version", null: false
    t.datetime "occurred_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.jsonb "provenance", default: {}, null: false
    t.integer "sequence", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_event_records_on_actor_id"
    t.index ["event_stream_id", "command_id"], name: "index_event_records_on_event_stream_id_and_command_id"
    t.index ["event_stream_id", "sequence"], name: "index_event_records_on_event_stream_id_and_sequence", unique: true
    t.index ["event_stream_id"], name: "index_event_records_on_event_stream_id"
    t.index ["event_type", "event_version"], name: "index_event_records_on_event_type_and_event_version"
  end

  create_table "event_streams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "domain_id", null: false
    t.integer "revision", default: 0, null: false
    t.string "stream_type", null: false
    t.uuid "subject_id", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_event_streams_on_domain_id"
    t.index ["stream_type", "subject_id"], name: "index_event_streams_on_stream_type_and_subject_id", unique: true
  end

  create_table "external_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "canonical_uri", null: false
    t.datetime "created_at", null: false
    t.uuid "document_id", null: false
    t.datetime "imported_at"
    t.datetime "last_checked_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "source_kind", null: false
    t.string "source_uri"
    t.datetime "updated_at", null: false
    t.index ["canonical_uri"], name: "index_external_documents_on_canonical_uri", unique: true
    t.index ["document_id"], name: "index_external_documents_on_document_id", unique: true
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "actor_id", null: false
    t.uuid "body_id", null: false
    t.datetime "created_at", null: false
    t.datetime "effective_from", null: false
    t.datetime "effective_until"
    t.jsonb "provenance", default: {}, null: false
    t.uuid "recorded_by_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_memberships_on_actor_id"
    t.index ["body_id", "actor_id", "effective_from"], name: "index_memberships_on_body_actor_effective_from"
    t.index ["body_id"], name: "index_memberships_on_body_id"
    t.index ["recorded_by_id"], name: "index_memberships_on_recorded_by_id"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.uuid "room_id", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_messages_on_room_id"
  end

  create_table "revisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "body", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.uuid "document_id", null: false
    t.text "message"
    t.uuid "parent_revision_id"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_revisions_on_created_by_id"
    t.index ["document_id", "created_at"], name: "index_revisions_on_document_id_and_created_at"
    t.index ["document_id"], name: "index_revisions_on_document_id"
    t.index ["parent_revision_id"], name: "index_revisions_on_parent_revision_id"
  end

  create_table "role_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "actor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "effective_from", null: false
    t.datetime "effective_until"
    t.jsonb "provenance", default: {}, null: false
    t.uuid "recorded_by_id"
    t.string "role", null: false
    t.uuid "scope_id", null: false
    t.string "scope_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_role_assignments_on_actor_id"
    t.index ["recorded_by_id"], name: "index_role_assignments_on_recorded_by_id"
    t.index ["scope_type", "scope_id", "actor_id", "role", "effective_from"], name: "index_role_assignments_on_scope_actor_role_from"
  end

  create_table "rooms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "schema_wrappers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "default_board_id"
    t.uuid "document_id", null: false
    t.boolean "public", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["default_board_id"], name: "index_schema_wrappers_on_default_board_id"
    t.index ["document_id"], name: "index_schema_wrappers_on_document_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "external_id"
    t.string "identity_issuer"
    t.string "identity_subject"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["external_id"], name: "index_users_on_external_id", unique: true
    t.index ["identity_issuer", "identity_subject"], name: "index_users_on_identity_issuer_and_subject", unique: true, where: "((identity_issuer IS NOT NULL) AND (identity_subject IS NOT NULL))"
  end

  create_table "view_affordances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "public", default: false, null: false
    t.uuid "schema_wrapper_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "view_document_id", null: false
    t.index ["schema_wrapper_id", "title"], name: "index_view_affordances_on_schema_wrapper_and_title", unique: true
    t.index ["view_document_id"], name: "index_view_affordances_on_view_document_id"
  end

  add_foreign_key "boards", "documents", column: "board_document_id"
  add_foreign_key "boards", "schema_wrappers"
  add_foreign_key "bodies", "documents", column: "body_document_id"
  add_foreign_key "document_index_entries", "documents"
  add_foreign_key "document_index_entries", "documents", column: "schema_document_id"
  add_foreign_key "document_index_entries", "revisions"
  add_foreign_key "documents", "documents", column: "schema_document_id"
  add_foreign_key "documents", "domains"
  add_foreign_key "documents", "revisions", column: "head_revision_id"
  add_foreign_key "domain_commit_documents", "documents"
  add_foreign_key "domain_commit_documents", "domain_commits"
  add_foreign_key "domain_commit_documents", "revisions"
  add_foreign_key "domain_commits", "domain_commits", column: "parent_domain_commit_id"
  add_foreign_key "domain_commits", "domains"
  add_foreign_key "domain_commits", "users", column: "created_by_id"
  add_foreign_key "domains", "domain_commits", column: "head_domain_commit_id"
  add_foreign_key "domains", "users", column: "owner_id"
  add_foreign_key "drafts", "documents"
  add_foreign_key "drafts", "revisions", column: "based_on_revision_id"
  add_foreign_key "drafts", "users", column: "created_by_id"
  add_foreign_key "edit_affordances", "documents", column: "edit_document_id"
  add_foreign_key "edit_affordances", "schema_wrappers"
  add_foreign_key "event_records", "event_streams"
  add_foreign_key "event_records", "users", column: "actor_id"
  add_foreign_key "event_streams", "domains"
  add_foreign_key "external_documents", "documents"
  add_foreign_key "memberships", "bodies"
  add_foreign_key "memberships", "users", column: "actor_id"
  add_foreign_key "memberships", "users", column: "recorded_by_id"
  add_foreign_key "messages", "rooms"
  add_foreign_key "revisions", "documents"
  add_foreign_key "revisions", "revisions", column: "parent_revision_id"
  add_foreign_key "revisions", "users", column: "created_by_id"
  add_foreign_key "role_assignments", "users", column: "actor_id"
  add_foreign_key "role_assignments", "users", column: "recorded_by_id"
  add_foreign_key "schema_wrappers", "boards", column: "default_board_id", on_delete: :nullify
  add_foreign_key "schema_wrappers", "documents"
  add_foreign_key "view_affordances", "documents", column: "view_document_id"
  add_foreign_key "view_affordances", "schema_wrappers"
end
