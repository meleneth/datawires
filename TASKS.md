# Task List

## Model Redesign Goals

- [x] Rename `SchemaDocument` to `SchemaWrapper` so the wrapper is clearly derived app metadata around a schema `Document`, not the schema document itself.
- [x] Replace the placeholder JSON Schema 2020-12 seed with the actual vendored meta-schema JSON. The bootstrap document should be committed, self-schema-backed, and have a `SchemaWrapper`.
- [ ] Require committed schema documents to have a key. Make ordinary document keys optional later; UUID remains the canonical system identity.
- [x] Require drafts to belong to a user. Keep one open draft per document/user, store full mutable draft bodies, and destroy only the committing user's draft.
- [x] Keep document shells for new document/schema drafts, but hide uncommitted shells from committed lists and delete a shell when its never-committed draft is discarded.
- [ ] Add `DraftCommitPreflight` for user-facing semantic blockers, starting with unsupported `$schema` declarations requiring confirmation.
- [ ] Add `SyncSchemaWrapperForDocument` and call it synchronously from `PublishDraft` after `head_revision` advances.
- [ ] Clear dependent document `schema_document_id` values when a schema document stops being a supported schema.
- [ ] Add `EditAffordances::Generated` as the default PORO affordance for schema-backed documents; stored `EditAffordance` records are bespoke alternatives.
- [ ] Move runtime edit projection objects into the `EditAffordances::*` namespace while keeping `EditAffordance` as the ActiveRecord model.
- [ ] Reconcile editor routes/controllers so every route in `routes.rb` has a real owner or is removed.
- [ ] Add full flow coverage for schema creation, document creation, draft editing, stale commit rejection, and schema wrapper synchronization.
