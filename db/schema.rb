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

ActiveRecord::Schema[8.1].define(version: 2026_03_17_205451) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "domain_id", null: false
    t.uuid "head_revision_id"
    t.string "key", null: false
    t.uuid "schema_document_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["domain_id", "key"], name: "index_documents_on_domain_id_and_key", unique: true
    t.index ["domain_id"], name: "index_documents_on_domain_id"
    t.index ["head_revision_id"], name: "index_documents_on_head_revision_id"
    t.index ["schema_document_id"], name: "index_documents_on_schema_document_id"
  end

  create_table "domains", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_domains_on_slug"
  end

  create_table "drafts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "based_on_revision_id"
    t.jsonb "body", default: {}, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.uuid "document_id", null: false
    t.datetime "updated_at", null: false
    t.index ["based_on_revision_id"], name: "index_drafts_on_based_on_revision_id"
    t.index ["created_by_id"], name: "index_drafts_on_created_by_id"
    t.index ["document_id", "created_by_id"], name: "index_drafts_on_document_id_and_created_by_id", unique: true
    t.index ["document_id"], name: "index_drafts_on_document_id"
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

  create_table "rooms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "documents", "documents", column: "schema_document_id"
  add_foreign_key "documents", "domains"
  add_foreign_key "documents", "revisions", column: "head_revision_id"
  add_foreign_key "drafts", "documents"
  add_foreign_key "drafts", "revisions", column: "based_on_revision_id"
  add_foreign_key "drafts", "users", column: "created_by_id"
  add_foreign_key "messages", "rooms"
  add_foreign_key "revisions", "documents"
  add_foreign_key "revisions", "revisions", column: "parent_revision_id"
  add_foreign_key "revisions", "users", column: "created_by_id"
end
