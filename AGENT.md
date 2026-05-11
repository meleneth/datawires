# Repository Guidelines

## Project Overview

Datawires is a Ruby on Rails 8.1 application using PostgreSQL, Haml views,
Hotwire/Turbo, Importmap, Tailwind CSS, ViewComponent, and RSpec. The app models
domains, documents, immutable revisions, drafts, schemas, rooms, messages, and
users. JSON document navigation and mutation helpers live in `lib/json_ptr.rb`
and `app/lib`.

## Common Commands

- Setup/update dependencies and database: `bin/setup`
- Run the development server and Tailwind watcher: `bin/dev`
- Run the CI workflow: `bin/ci`
- Run tests: `bundle exec rspec`
- Run Ruby style checks: `bin/rubocop`
- Run security checks: `bin/bundler-audit` and `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`

`bin/dev` uses Foreman with `Procfile.dev`; the web process binds Rails to
`0.0.0.0:3000`, and the CSS process rebuilds Tailwind every 2 seconds.

## Architecture Notes

- `Document` belongs to a `Domain`, has a nullable `head_revision`, and may point
  at another `Document` as its `schema_document`.
- `Revision` is the immutable document history node. It validates JSON object
  bodies and raises on update.
- `Draft` is the mutable editing state for a document and tracks the revision it
  was based on.
- `PublishDraft` is the current revision-based publishing service. It locks the
  draft and document, checks staleness, creates a `Revision`, updates
  `head_revision`, and destroys the draft.
- `app/services/commit_draft.rb` appears to reference an older commit/snapshot
  model shape (`head_commit`, `document_snapshot`, `draftable`, etc.). Treat it
  as stale unless the schema is reintroduced.
- Schema and document editing are routed through `DraftsController`, nested schema
  controllers, and helpers such as `DocumentProjection`, `DocumentPath`,
  `SchemaPath`, and `JsonPtr`.

## Testing Conventions

RSpec specs are under `spec/`, with factories in `spec/factories`. Existing tests
cover models, services, request flows, components, and JSON pointer behavior.
For changes to draft publishing, document history, schema mutation, or JSON
pointer operations, add or update focused specs near the existing service/lib
coverage.

## Working Notes

- Preserve user changes in the working tree. At initialization time,
  `Gemfile.lock` was modified and `fetch.sh` was untracked.
- Prefer existing Rails, Haml, ViewComponent, Turbo, and Tailwind patterns over
  introducing new frontend or service abstractions.
- Keep document bodies as JSON-compatible Ruby hashes/arrays/scalars and prefer
  the existing `JsonPtr` helpers for pointer parsing, lookup, and mutation.
