# Datawires

Datawires is a Rails 8.1 application for editing JSON documents through schema-backed affordances. The core rule is that committed JSON document bodies are the source of truth. Drafts are mutable working copies; committing a draft creates an immutable revision and advances the document body.

## Stack

- Ruby on Rails 8.1
- PostgreSQL
- Haml views
- Hotwire/Turbo
- Importmap
- Tailwind CSS
- ViewComponent
- RSpec and FactoryBot

## Setup

Install dependencies and prepare the database:

```sh
bin/setup --skip-server
```

Run migrations and seeds directly when needed:

```sh
bin/rails db:prepare
bin/rails db:seed
```

The seed data vendors the official JSON Schema draft 2020-12 meta-schema files from `db/seeds/vendor/json_schema_2020_12/`.

## Development

Start the development server:

```sh
bin/dev
```

`Procfile.dev` runs Rails on `0.0.0.0:3000`. The Tailwind watcher is currently commented out in `Procfile.dev`.

## Tests

Run the test suite:

```sh
bundle exec rspec
```

Known local issue: specs can pass and then exit nonzero because SimpleCov cannot overwrite `coverage/assets/0.13.2/DataTables-1.10.20/images/sort_asc.png`. The failure happens after RSpec reports examples and failures.

## Domain Model

- `Domain` groups documents.
- `Document` is the stable identity for a JSON document. Its UUID is the canonical system identity.
- `Revision` stores immutable committed JSON object bodies.
- `Draft` stores a user's mutable full-body working copy before commit.
- `SchemaWrapper` is derived application metadata around a `Document` whose committed body is a supported JSON Schema.
- `EditAffordance` and `ViewAffordance` are persisted bespoke affordance records attached to a `SchemaWrapper`.
- `EditAffordances::Generated` is the default runtime edit affordance for schema-backed documents.

Supported JSON Schema currently means:

```json
{ "$schema": "https://json-schema.org/draft/2020-12/schema" }
```

Unsupported `$schema` declarations are treated as `not_schema` after explicit commit confirmation.

## Draft Commit Semantics

Drafts are per user. A document can have multiple open drafts, but only one per user.

Commit behavior:

- validates commit preflight warnings;
- rejects stale drafts when their `based_on_revision` is not the current document head;
- creates a new immutable `Revision`;
- advances `Document#head_revision`;
- synchronizes `SchemaWrapper` state from the committed body;
- destroys only the committing user's draft;
- redirects to the committed document.

`SchemaWrapper` state is synchronized only at commit time. Editing a draft does not create, remove, or update wrapper metadata.

When a committed schema document stops being a supported schema, its wrapper is removed and dependent documents have `schema_document_id` cleared.

## Editing Model

Schema-backed documents always have an edit path through `EditAffordances::Generated`. Bespoke `EditAffordance` records are optional alternatives, not replacements for the generated default.

Generated affordances expose immediate schema properties as editable fields. Fields may reference deeper document pointers when a bespoke affordance is used.

Runtime projection objects live under `EditAffordances::*`:

- `EditAffordances::Generated`
- `EditAffordances::ProjectedRow`
- `EditAffordances::ProjectedField`
- `EditAffordances::ProjectedCommit`
- `EditAffordances::CellBinding`

The ActiveRecord model remains singular: `EditAffordance`.

## Routes And Controllers

Draft editing is handled by:

- `DraftsController`
- `Drafts::CommitsController`
- `Drafts::SchemaPropertiesController`
- `Documents::DraftsController`
- `Schemas::DocumentsController`

Routes in `config/routes.rb` should have real controller owners. Remove dead routes rather than leaving missing-controller paths behind.

## Useful Commands

```sh
bin/rails routes
bundle exec rspec spec/requests/schema_document_flow_spec.rb
bundle exec rspec spec/services/publish_draft_spec.rb
bin/rubocop
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
```
