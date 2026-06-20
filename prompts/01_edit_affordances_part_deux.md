# Datawires Editor Design Notes

These notes describe the current draft editor direction. Keep them aligned with
the code before using them as implementation guidance.

## Core Rules

- JSON document bodies are the source of truth.
- Drafts are mutable full-body working copies.
- Revisions are immutable committed bodies.
- Derived metadata updates at commit time, not while a draft is being edited.
- A committed document is a supported schema only when its body declares
  `$schema: "https://json-schema.org/draft/2020-12/schema"`.
- Unsupported schema declarations are committed as `not_schema` only after
  explicit user confirmation.

## Schema Wrapper

`SchemaWrapper` is derived app metadata around a schema `Document`. It is not the
schema document itself.

Commit-time behavior:

- supported schema body: ensure the document has a `SchemaWrapper`;
- non-schema or unsupported schema body: remove the wrapper;
- wrapper removal clears dependent document `schema_document_id` values.

Draft edits never create or remove wrappers.

## Documents And Drafts

- `Document` UUID is the canonical identity.
- `Document#key` is required for committed supported schema documents.
- Ordinary documents may be keyless.
- Drafts belong to a user.
- Each user gets at most one open draft per document.
- Commit destroys only the committing user's draft.
- Stale drafts stay editable, but commit is rejected when `based_on_revision`
  differs from the current document head.
- After commit, the user should be looking at the committed document.

## Affordances

Schema-backed documents always have an edit affordance:

- `EditAffordances::Generated` is the default runtime affordance generated from
  the schema.
- Persisted `EditAffordance` records are bespoke alternatives.
- The ActiveRecord model remains `EditAffordance`.
- Runtime projection objects live under `EditAffordances::*`.

Generated affordances expose immediate schema properties. Bespoke affordances may
reference deeper document pointers.

Runtime classes:

- `EditAffordances::Generated`
- `EditAffordances::ProjectedRow`
- `EditAffordances::ProjectedField`
- `EditAffordances::ProjectedCommit`
- `EditAffordances::CellBinding`

## Cursor And Projection

- `Documents::Cursor` is the document location object. It wraps `source` and
  `path`.
- Cursor navigation is persistent: `at`, `child`, and `parent` return new cursor
  objects.
- Cursor owns schema-aware conveniences such as `ptr`, `value`, `schema_node`,
  `children`, `input_kind`, `field_value`, `checkbox_value`, `array?`,
  `object?`, and `scalar?`.
- Affordances interpret layout and produce projected rows/cells.
- Projected rows/cells are render-shape data, not interpreters.
- `Drafts::ShowPage` is the page/view-model object for `DraftsController#show`.

## Editor Behavior

- Scalar autosave is non-navigational.
- Scalar autosave should preserve the input being edited.
- Structural edits, such as adding an array item or schema property, may rerender
  the editor surface.
- Review/diff is a separate reactive surface from the editor.
- Diff should be against the current committed body, not an old draft baseline,
  when presenting commit risk to the user.

## Hotwire And Haml

- Prefer stable Turbo frame shells and update their contents.
- `broadcast_update_to` updates target contents; `broadcast_replace_to` replaces
  the target element itself.
- `turbo_stream_from` is used directly in Haml.
- Haml is picky: a tag cannot have same-line content and nested content. For
  nested nodes, put class names in dotted syntax or `class:`.
- Keep Haml templates thin. Branching, component selection, and option building
  should live in Ruby components or page objects.

## Routes

Every route in `config/routes.rb` should have a real controller owner. Do not
leave missing-controller routes in place. Remove stale scaffold routes instead
of preserving dead surface area.

Current draft/editor owners:

- `DraftsController`
- `Drafts::CommitsController`
- `Drafts::SchemaPropertiesController`
- `Documents::DraftsController`
- `Schemas::DocumentsController`

## Known Follow-Ups

- Add orphaned document verifier/tooling.
- Improve stale draft user experience.
- Build richer bespoke affordance authoring.
- Keep README, AGENT, and these notes synchronized with implementation changes.
