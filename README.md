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

On devastation, development uses the local Postgres service at
`localhost:5434/datawires_development` and tests use the isolated database at
`localhost:5433/datawires_test`. The default local credentials are
`devastation` / `devastation`. Override the connection with `DATABASE_URL` or
the `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USERNAME`, and
`DATABASE_PASSWORD` environment variables.

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

Local Keystone identity is expected to arrive through request headers from the
dev auth gateway at `https://keystone.deva.station`. Datawires reads:

- `X-Keystone-User-Id`
- `X-Keystone-User-Name`
- `X-Keystone-User-Email`
- `X-Keystone-User-Avatar`

If those are absent, Datawires accepts oauth2-proxy's `X-Forwarded-User`,
`X-Forwarded-Preferred-Username`, and `X-Forwarded-Email` headers. It also
accepts `X-Remote-User` or Rack `REMOTE_USER` as both the external id and
display name.

Override those with `KEYSTONE_USER_ID_HEADER`, `KEYSTONE_USER_NAME_HEADER`,
`KEYSTONE_USER_EMAIL_HEADER`, and `KEYSTONE_USER_AVATAR_HEADER`. `KEYSTONE_URL`
defaults to `https://keystone.deva.station` for local environment wiring.
The normalized actor key is the pair of `OIDC_ISSUER` and the selected external
subject header. Existing `external_id` users are adopted on first matching
request for migration compatibility. Equal subject strings from different
issuers remain distinct actors.

Request identity is captured as an immutable claims snapshot containing the
issuer, subject, profile fields, and optional group, organization, and broad
administrative-role hints. Those hints identify context only: Datawires
authorization returns an explicit allow/deny decision with a reason, and later
domain Memberships and RoleAssignments—not Keycloak groups—will determine
parliamentary capabilities.

The current user's profile links through oauth2-proxy logout and then Keycloak
logout. Override its defaults with `OIDC_ISSUER`, `OIDC_CLIENT_ID`, and
`LOGOUT_REDIRECT_URL`.

## Tests

Run the test suite:

```sh
bundle exec rspec
```

Run browser e2e tests:

```sh
npm install
npx playwright install chromium
npm run test:e2e
```

The Playwright harness uses `datawires_playwright` on devastation's test
Postgres service so its persistent browser fixtures do not contaminate the
transactional RSpec database.

Known local issue: specs can pass and then exit nonzero because SimpleCov cannot overwrite `coverage/assets/0.13.2/DataTables-1.10.20/images/sort_asc.png`. The failure happens after RSpec reports examples and failures.

## Domain Model

- `Domain` groups documents. Domains are owned by users and can be public or private.
- `Document` is the stable identity for a JSON document. Its UUID is the canonical system identity.
- `Revision` stores immutable committed JSON object bodies.
- `Draft` stores a user's mutable full-body working copy before commit.
- `SchemaWrapper` is derived application metadata around a `Document` whose committed body is a supported JSON Schema.
- `EditAffordance` and `ViewAffordance` are persisted bespoke affordance records attached to a `SchemaWrapper`.
- `EditAffordances::Generated` is the default runtime edit affordance for schema-backed documents.
- `Body` identifies a schema-backed deliberative body document.
- `Membership` is an effective-dated relationship between an actor and a Body.
- `RoleAssignment` is an effective-dated, provenance-bearing actor relationship
  scoped to a domain object. The initial supported scope is `Body`; Meeting
  scope will be added with the Meeting model.
- Body capabilities are evaluated from effective Datawires relationships at an
  explicit instant. Identity-provider groups are not procedural roles.
- `EventStream` is a domain-neutral, revisioned stream for one typed subject.
  `Commands::Envelope` carries the authenticated actor, expected revision,
  versioned payload, timestamp, and correlation/causation ids.
- `EventRecord` is append-only and versioned. Atomic appends serialize on the
  stream revision, return prior records for an idempotent command retry, reject
  stale revisions, and retain issuer/subject provenance for deterministic
  replay and audit.
- `Meeting` is a schema-backed identity associated with a `Body` and one
  matching `EventStream`. Its operational status, attendance, quorum finding,
  and adjournment are rebuilt from ordered events rather than mutable Meeting
  fields.
- Initial Meeting lifecycle commands are authorized from effective Body and
  Meeting-scoped roles, procedurally validated against the current projection,
  and appended through the generic optimistic event store.
- Recognition requests and control of the floor are explicit Meeting events and
  projection state. The projection retains ordered requests, the one current
  floor holder, grant/end reasons, and participation history; relinquishment
  and adjournment end the floor without rewriting prior events.
- `Proposal` is a schema-backed document submitted to a `Body` with immutable
  lineage to the exact submitted `Revision`. Scheduling records that revision
  in the Meeting event stream but deliberately leaves the pending-question
  stack empty; a Proposal is not a Motion or pending business.

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
