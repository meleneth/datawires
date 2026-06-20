# Repository Guidelines

## Project Overview

Datawires is a Ruby on Rails 8.1 application using PostgreSQL, Haml views,
Hotwire/Turbo, Importmap, Tailwind CSS, ViewComponent, and RSpec. The app models
domains, JSON documents, immutable revisions, per-user drafts, schema wrappers,
edit/view affordances, and users. JSON document navigation and mutation helpers
live in `lib/json_ptr.rb` and `app/lib`.

## Common Commands

- Setup/update dependencies and database: `bin/setup`
- Run the development server and Tailwind watcher: `bin/dev`
- Run the CI workflow: `bin/ci`
- Run tests: `bundle exec rspec`
- Run Ruby style checks: `bin/rubocop`
- Run security checks: `bin/bundler-audit` and `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`

`bin/dev` uses Foreman with `Procfile.dev`; the web process binds Rails to
`0.0.0.0:3000`. The CSS watcher entry is currently commented out in
`Procfile.dev`.

## Architecture Notes

- JSON document bodies are the source of truth. Derived metadata follows the
  committed body, not draft contents.
- `Document` belongs to a `Domain`, has a nullable `head_revision`, and may point
  at another `Document` as its `schema_document`. UUID is the canonical system
  identity. `key` is required for committed supported schema documents; ordinary
  documents may be keyless.
- `Revision` is the immutable document history node. It validates JSON object
  bodies and raises on update.
- `Draft` is the mutable full-body editing state for one document and one user.
  It tracks the revision it was based on.
- `SchemaWrapper` is derived application metadata around a supported JSON Schema
  `Document`. Supported schema currently means `$schema` is exactly
  `https://json-schema.org/draft/2020-12/schema`.
- `PublishDraft` is the current revision-based publishing service. It locks the
  draft and document, checks staleness, creates a `Revision`, updates
  `head_revision`, synchronizes `SchemaWrapper` state, and destroys only the
  committing user's draft.
- `DraftCommitPreflight` owns user-visible commit warnings. Unsupported
  `$schema` declarations require confirmation and then commit as `not_schema`.
- `EditAffordances::Generated` is the default runtime edit affordance for
  schema-backed documents. Persisted `EditAffordance` records are bespoke
  alternatives attached to a `SchemaWrapper`.
- Runtime edit projection objects live in `EditAffordances::*`. The ActiveRecord
  model remains `EditAffordance`.
- `app/services/commit_draft.rb` appears to reference an older commit/snapshot
  model shape (`head_commit`, `document_snapshot`, `draftable`, etc.). Treat it
  as stale unless the schema is reintroduced.
- Schema and document editing are routed through `DraftsController`,
  `Drafts::CommitsController`, `Drafts::SchemaPropertiesController`,
  `Documents::DraftsController`, `Schemas::DocumentsController`, and helpers
  such as `Documents::Cursor`, `Documents::Path`, `Schemas::Path`, and `JsonPtr`.

## Testing Conventions

RSpec specs are under `spec/`, with factories in `spec/factories`. Existing tests
cover models, services, request flows, components, and JSON pointer behavior.
For changes to draft publishing, document history, schema mutation, or JSON
pointer operations, add or update focused specs near the existing service/lib
coverage.

Specs may pass and then exit nonzero when SimpleCov cannot overwrite the locked
coverage asset `coverage/assets/0.13.2/DataTables-1.10.20/images/sort_asc.png`.
Check the RSpec examples/failures line before treating that as a test failure.

## Working Notes

- Prefer existing Rails, Haml, ViewComponent, Turbo, and Tailwind patterns over
  introducing new frontend or service abstractions.
- Haml is strict about same-line tag content: if a tag has nested children, do
  not leave class names or text after a space on the tag line. Chain Tailwind
  classes with dots (`%nav.flex.px-4.py-3`) or put attributes in `class:`.
- Keep document bodies as JSON-compatible Ruby hashes/arrays/scalars and prefer
  the existing `JsonPtr` helpers for pointer parsing, lookup, and mutation.
