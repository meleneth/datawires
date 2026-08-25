# Datawires Implementation Recon

This report describes the repository state inspected on 2026-08-25. It distinguishes active application paths from isolated scaffolding and does not propose a redesign.

## 1. Core document model

### Documents, revisions, and drafts

- `app/models/document.rb` — `Document` is the stable record and canonical UUID identity. It belongs to one `Domain`, points to a nullable current `head_revision`, may point to a schema `Document`, and carries mutable display metadata (`key`, `title`). `key` is unique within a domain (nullable except for supported schema documents); the committed JSON source of truth is `document.head_revision.body`, exposed by `Document#body`.
- `app/models/revision.rb`, `db/schema.rb` — `Revision` stores a full JSONB object body, optional message/author, and an optional same-document `parent_revision`. Updates raise `ActiveRecord::ReadOnlyRecord`; deletion is not similarly prohibited at model level, although document associations restrict deletion while revisions exist.
- `app/models/draft.rb` — `Draft` stores a mutable full JSONB body for exactly one `(document, created_by)` pair and records `based_on_revision`. Draft and revision bodies must be JSON objects, not arbitrary JSON scalars/arrays.
- `app/services/publish_draft.rb` — publication locks the draft and document, rejects stale bases, creates a child revision from the entire draft body, advances `head_revision`, optionally resolves a schema-defined key template, synchronizes schema metadata, optionally snapshots repository-mode domains, deletes only the publishing user's draft, and queues index rebuilding.
- `app/services/ensure_draft_for_document.rb`, `app/models/document.rb` (`draft_for`) — a user's draft is initialized from the current committed body and head revision.

Important tests: `spec/models/document_spec.rb`, `spec/models/revision_spec.rb`, `spec/models/draft_spec.rb`, `spec/services/publish_draft_spec.rb`, `spec/requests/draft_commits_spec.rb`, and `spec/requests/draft_discards_spec.rb`.

### JSON Schema integration

- `app/models/document.rb` — a document is treated as a supported schema only when its body declares `$schema` exactly as Draft 2020-12. `SyncSchemaWrapperForDocument` creates/removes the associated wrapper as this status changes.
- `app/models/schema_wrapper.rb` — `SchemaWrapper` is derived application metadata for a supported schema document. It owns edit affordances, view affordances, boards, and an optional default board; `conforming_documents` means documents whose `schema_document_id` points at the wrapped document.
- `app/lib/documents/schema_resolver.rb`, `app/lib/documents/resolved_path.rb`, `app/models/documents/cursor.rb`, `app/models/ptr/schema.rb`, `app/models/ptr/cursor.rb`, `lib/json_ptr.rb` — schema-aware cursors traverse `properties`/`items`, inspect types, required fields and enums, and resolve internal `#/...` `$ref` values. External `$ref` resolution is explicitly unsupported by `Documents::SchemaResolver` at runtime.
- `app/services/documents/key_template.rb` — the schema extension `x-datawires-document-key` supports Ruby-style `#{field}` / `#{nested.field}` substitutions during publication. Missing values raise; uniqueness validation causes duplicate generated keys to roll back the publish transaction.
- No general validation of an instance document body against its JSON Schema was found in the publish path or models. The `json-schema` gem is present transitively/in the lockfile, but repository searches found no application invocation of it. Schema currently drives navigation, initial values, generated editors, key generation, and classification—not complete conformance enforcement.

Important tests: `spec/models/schema_wrapper_spec.rb`, `spec/services/sync_schema_wrapper_for_document_spec.rb`, `spec/lib/documents/schema_resolver_spec.rb`, `spec/lib/documents/resolved_path_spec.rb`, `spec/lib/schema_paths/inventory_spec.rb`, `spec/requests/schema_document_flow_spec.rb`, and key-template examples in `spec/services/publish_draft_spec.rb`.

### References, IDs, namespaces, and ownership

- `Document#schema_document` is the principal persisted document-to-document relation. Affordance, board, body, meeting, proposal, and procedural-policy documents are also connected through typed wrapper records with foreign keys in `db/schema.rb`.
- JSON bodies use application-level key references rather than generic persisted graph edges. Edit-affordance reference fields resolve choices through `DocumentIndexEntry`; timeline participants and governance lineage similarly carry keys/UUIDs in JSON. There is no general relationship table for arbitrary document references.
- UUID primary keys (PostgreSQL `gen_random_uuid()`) identify all major records. A `Domain` is the namespace/grouping boundary: it owns documents and event streams; document keys are unique per domain.
- `app/models/domain.rb`, `app/models/user.rb`, `app/controllers/application_controller.rb` — domains optionally belong to an owner and have public/private visibility plus archival state. Legacy ownerless domains remain visible. Identity is resolved from trusted proxy/OIDC headers into `User`/`ActorContext`; there is no per-document owner column.
- `app/models/body.rb`, `app/models/membership.rb`, `app/models/role_assignment.rb` add governance-specific ownership/association concepts: memberships connect users to parliamentary bodies over effective-time intervals, while polymorphic role assignments scope roles to a resource.

Important tests: `spec/models/domain_spec.rb`, `spec/requests/domains_spec.rb`, `spec/requests/keystone_auth_spec.rb`, `spec/models/membership_spec.rb`, `spec/models/role_assignment_spec.rb`, and `spec/services/authorization/policy_spec.rb`.

## 2. Affordance system

### Declaration and resolution

- `app/models/edit_affordance.rb` — each bespoke `EditAffordance` associates a schema wrapper with a separate versioned document containing the edit DSL. The DSL supports screens/subforms, grid rows and spans, JSON-pointer bindings, widgets, collection behavior, navigation, commit controls, reference lookup, and derived index definitions.
- `app/models/edit_affordances/body_validator.rb`, `app/models/edit_affordances/versions.rb` — a handwritten validator defines the supported version and vocabulary. Invalid runtime DSL falls back to a generated editor; authoring mode retains per-cell diagnostics.
- `app/models/edit_affordances/generated.rb`, `app/lib/schema_paths/inventory.rb` — when no bespoke affordance is selected (or its usable layout is empty), a generated affordance walks the JSON Schema and builds fields/sections. Schema types and enums choose basic input kinds.
- `app/models/edit_affordance.rb` (`projection`), `app/models/edit_affordances/cells/*`, `app/components/drafts/projected_*` — DSL is resolved into runtime projection objects and rendered by ViewComponents. `Documents::Cursor` binds each projected field to draft JSON and its schema node.
- `app/controllers/documents/drafts_controller.rb`, `app/controllers/drafts_controller.rb`, `app/controllers/drafts/edit_affordance_builders_controller.rb` — controllers select a requested bespoke affordance or generated default, mutate draft JSON through pointer operations, and provide a structured/raw affordance builder.

Important tests: `spec/models/edit_affordance_spec.rb`, all `spec/models/edit_affordances/*_spec.rb`, `spec/requests/draft_generated_affordances_spec.rb`, `spec/requests/draft_bespoke_affordances_spec.rb`, `spec/requests/edit_affordance_builder_spec.rb`, and `spec/e2e/edit-affordance-builder.spec.ts`.

### View affordances, renderers, and actions

- `app/models/view_affordance.rb` — a `ViewAffordance` associates a schema wrapper with a separate versioned view-definition document. Multiple titled view affordances may exist for the same schema, so every conforming document can have multiple presentations.
- `app/models/view_affordances/body_validator.rb` — the schema-driven portion is a small versioned JSON DSL (`renderer`, title, config). Renderer names are a hard-coded allowlist: `timeline_d3`, `mud_player`, and `mud_choice_player`.
- `app/services/view_affordances/projection.rb`, `app/services/view_affordances/*_projection.rb`, `app/views/view_affordances/*` — a hard-coded dispatcher calls renderer-specific projection services and Haml partials. Adding a renderer currently requires Ruby validator/dispatcher code and a view (and often JavaScript), not only schema data.
- `app/models/board.rb`, `app/models/boards/projection.rb`, `app/services/boards/action_resolution.rb` — boards declare actions in JSON. `open_edit_affordance` resolves a target schema and optional named editor; `invoke_command` resolves a hard-coded registered domain command. Authorization determines available/disabled/hidden state.
- `app/services/boards/domain_commands/registry.rb` and `app/services/boards/domain_commands/*` are the action plug-in boundary presently used for governance operations. It is a Ruby registry, not a dynamically loaded plugin/adapter system.

Important tests: `spec/models/view_affordance_spec.rb`, `spec/models/view_affordances/body_validator_spec.rb`, `spec/requests/document_view_affordances_spec.rb`, `spec/models/boards/body_validator_spec.rb`, `spec/services/boards/action_resolution_spec.rb`, and `spec/requests/boards_spec.rb`.

## 3. History and versioning

- Per-document history is fully persisted as immutable, full-body `Revision` rows linked by `parent_revision_id`; `Document#head_revision` selects the live state. Updating a document never overwrites an old revision body.
- `app/services/documents/diff.rb` recursively produces added/removed/changed rows by JSON Pointer. It is used for draft review against `based_on_revision`; no general revision-to-revision diff route/UI was found.
- Old document states are directly reconstructable by loading a revision body. There is no restore/revert service or route; restoration would currently require creating/pointing to another revision through code.
- `app/models/domain_commit.rb`, `app/models/domain_commit_document.rb`, `app/services/domain_commits/create.rb` — repository-mode domains additionally capture every current document head in a chained, SHA-256 state snapshot. Each entry stores the exact revision and a canonical body hash; the UI lists commits and constituent revisions.
- `app/services/domain_exports/export.rb` and `import.rb` serialize and recreate all document revisions, parent links, heads, affordances, and domain commits. Boards, external-document metadata, events, governance wrappers, authors/timestamps, and public affordance flags are not included in archive format v2, based on the payload fields present.
- `app/services/commit_draft.rb` refers to absent older concepts (`head_commit`, snapshots, draftable) and is not routed from the current flow; repository guidance identifies it as stale.

Important tests: `spec/models/revision_spec.rb`, `spec/services/publish_draft_spec.rb`, `spec/services/domain_commits/create_spec.rb`, `spec/requests/domain_commits_spec.rb`, `spec/services/domain_exports/export_import_spec.rb`, and draft-review expectations in `spec/requests/draft_commits_spec.rb`.

## 4. Data and query capabilities

### Append-only/event/time-series data

- `app/models/event_stream.rb`, `app/models/event_record.rb`, `app/services/event_streams/append.rb` — event streams are domain-scoped runtime aggregates identified by `(stream_type, subject_id)`. Appends lock the stream, enforce optimistic expected revision and command idempotency, assign ordered sequences, and persist versioned payloads plus command/identity provenance. Event records reject update and destroy, making them append-only through the model API.
- `app/models/meeting.rb`, `app/models/meetings/projection.rb`, `app/services/meetings/*`, `app/services/procedural_policies/*` — meetings are the concrete consumer: commands are evaluated against JSON policy documents, appended as events, and folded into a runtime meeting projection.
- Timeline data is not a separate time-series store. It is ordinary schema-backed documents (not append-only) with fields such as `relative_time`, indexed and rendered specially by `DocumentIndexes::Rebuild` and `ViewAffordances::TimelineD3Projection`.

Important tests: `spec/models/event_record_spec.rb`, `spec/services/event_streams/append_spec.rb`, `spec/models/meetings/projection_spec.rb`, `spec/services/meetings/handle_command_spec.rb`, and the procedural-policy service specs.

### Querying, filtering, indexes, and derivation

- ActiveRecord scopes provide basic domain/schema/head/visibility lookup. There is no general public query language, aggregation API, or ad hoc reporting subsystem.
- `app/models/document_index_entry.rb`, `app/services/document_indexes/rebuild.rb` — denormalized current-head entries index identity values and timeline participants. Rebuild deletes a document's prior entries, tags new entries with the exact source revision, and ignores a queued stale revision.
- `app/services/document_indexes/configured_definitions.rb` — edit-affordance JSON can define derived indexes using root/context JSON pointers, array iteration, simple conditions (`equals`, `in`, `all`), literals, labels, metadata, and a `strip_prefix` transform. This derives lookup/query material, not arbitrary computed document values or aggregates.
- `app/services/boards/document_collection.rb` — board collections filter documents with equality on JSON pointers, sort by metadata or a body pointer, limit results, and optionally route through a named view affordance. Meeting/proposal/membership/role collections are separate hard-coded query services.
- `app/services/document_indexes/rebuild.rb` contains application-specific temporal derivation: party membership is reconstructed from earlier timeline-event documents to add implicit person participants. `app/services/boards/proposal_collection.rb` similarly derives open/decided state by scanning decision lineage.
- `app/services/voting/tally_counted_vote.rb` computes governance vote totals, and meeting projections compute state from events. No generic formula/derived-metric document concept was found.

Important tests: `spec/services/document_indexes/configured_definitions_spec.rb`, `spec/services/document_indexes/rebuild_spec.rb`, `spec/jobs/document_indexes/rebuild_job_spec.rb`, `spec/services/boards/document_collection_spec.rb`, `spec/services/boards/proposal_collection_spec.rb`, and `spec/services/voting/tally_counted_vote_spec.rb`.

### Provenance

- Event provenance is explicit and strong: each `EventRecord` records the command envelope, actor issuer/subject, correlation/causation IDs, versions, timestamp, and arbitrary event-specific provenance.
- Derived document indexes retain `revision_id`, so an index row identifies the exact document revision from which it was built. Current rebuild semantics remove older index rows, so this table is not itself an index-history ledger.
- Revisions record author/message/parent, proposals pin a `submitted_revision`, and domain commits pin all included revisions and hashes. Ordinary produced documents do not have a general `produced_by configuration revision` relation; domain-specific JSON lineage/provenance fields exist but are not enforced as a common model.

## 5. UI composition

- `Board` is the primary persisted layout/dashboard/workspace concept. Its backing document uses the `datawires-board` schema and declares title, description, opaque `layout`, ordered `sections`, and `actions`; `SchemaWrapper#default_board` and sibling boards allow multiple workspaces for a schema.
- `Boards::BodyValidator` recognizes document, meeting, proposal, membership, role-assignment, and summary section kinds. `BoardsController` implements all except `summary`; the Haml template renders every implemented section through the same card/list shell. The `layout` object is preserved in projection but is not consumed in `app/views/boards/show.html.haml`.
- `Ui::CardComponent`/`CardComponent`-style components are visual primitives, not persistent domain cards. There is no separate persistent `Card` or `Panel` model.
- View affordances are reusable schema-level presentations. A document page lists all view affordances on its schema, while board collections may choose one by title; thus one document can have raw JSON plus multiple custom presentations.
- Renderer selection is the hard-coded view-affordance dispatch described above. `timeline_d3` uses `app/javascript/controllers/timeline_view_controller.js` and D3; MUD renderers use server-side projection services/partials.
- Edit UI composition is richer and data-driven: screens, subforms, rows, cells, widths/spans, collection cards/lists/tables, and widgets are declared in edit-affordance documents and rendered through `app/components/drafts/*`.

Important tests: `spec/models/board_spec.rb`, `spec/models/boards/body_validator_spec.rb`, `spec/requests/boards_spec.rb`, `spec/requests/document_view_affordances_spec.rb`, and the edit-affordance projection/request/e2e specs listed above.

## 6. External integration

- HTML is the principal routed interface. `DomainsController` also exposes Rails/Jbuilder JSON for domain index/show; no document JSON API, event ingestion API, webhook endpoint, GraphQL endpoint, or API-token authentication was found in `config/routes.rb`.
- `script/import_json.rb` is a CLI importer for file or URL JSON. It can follow/import schema references, upsert documents by domain/key, create revisions, and persist `ExternalDocument` metadata (`canonical_uri`, source URI/kind, import/check timestamps). `ExternalDocument` accepts only `url` and `file` kinds.
- No application service/controller/job was found that periodically fetches `ExternalDocument`; import behavior remains embedded in the script. `last_checked_at` and `imported_at` are persisted hooks without an in-app polling implementation.
- Active Job/Solid Queue is configured. Publishing queues `DocumentIndexes::RebuildJob`. `config/recurring.yml` schedules only Solid Queue cleanup in production; no source refresh or ingestion schedule exists.
- Rails encrypted credentials infrastructure and deployment placeholders exist, but there is no Datawires source-credential/secret model or vault abstraction. Authentication trusts proxy-provided Keystone/OIDC identity headers and environment configuration in `ApplicationController`.
- No general plugin, adapter, connector, or source registry was found. Renderer dispatch, board collection kinds, board commands, import source kinds, and cluster catalogs are closed Ruby registries/case statements or configuration catalogs.

Important tests: `spec/requests/domains_spec.rb` (JSON responses), `spec/jobs/document_indexes/rebuild_job_spec.rb`, `spec/requests/keystone_auth_spec.rb`. No focused tests for `ExternalDocument` or `script/import_json.rb` were found.

## 7. Extension boundaries

The clearest intended extension points are:

- `Clusters::Catalog`, `Clusters::SeedDomain`, `Clusters::SyncInstalled` (`app/services/clusters/*`) — catalog and idempotent installation/upgrade of schema/affordance clusters.
- JSON Schema documents plus `SchemaWrapper` — declare domain document shapes and attach presentations/workspaces.
- `EditAffordance`, `EditAffordances::BodyValidator`, projection/cell classes, and draft ViewComponents — extend editor DSL vocabulary and rendering.
- `ViewAffordance`, `ViewAffordances::BodyValidator`, `ViewAffordances::Projection`, renderer projection services, partials, and Stimulus controllers — extend presentations, currently through coordinated code changes.
- `Board`, `Boards::BodyValidator`, `Boards::Projection`, collection services, `Boards::ActionResolution`, and `Boards::DomainCommands::Registry` — extend dashboard section/action vocabulary and executable domain commands.
- `DocumentIndexes::ConfiguredDefinitions` and `DocumentIndexes::Rebuild` — add schema/editor-declared or coded lookup derivations.
- `EventStreams::Append`, `Commands::Envelope`, `Events::Data`, procedural policy evaluation/effects, and aggregate projections such as `Meetings::Projection` — extend command/event-driven behavior.
- `Authorization::Policy` / `Authorization::BodyPolicy` — central action/resource decisions.
- `DomainExports::Export` / `Import` — archive format boundary, although current v2 does not cover every persistent concept.

Application-specific behavior embedded in core-facing paths includes worldbuilding party membership inside `DocumentIndexes::Rebuild`; MUD and timeline renderer names in the generic view-affordance validator/dispatcher; governance collection kinds in `BoardsController`/`Boards::BodyValidator`; governance commands in the board registry; and identity-provider defaults/header parsing in `ApplicationController`.

## Current Domain Model

```text
User
  ├── owns Domain (optional; Domain also has public/archive flags)
  ├── owns Draft and authors Revision/DomainCommit/EventRecord
  ├── Membership ──> Body
  └── RoleAssignment ──> polymorphic scope

Domain (namespace; optional repository mode)
  ├── Document* ──head──> Revision* ──parent──> Revision
  │      ├── schema_document ──> Document (supported JSON Schema)
  │      ├── Draft* (one per user, based_on_revision)
  │      ├── DocumentIndexEntry* (for current revision; points to schema + revision)
  │      ├── ExternalDocument? (source metadata)
  │      └── typed wrapper? (Board / Body / Meeting / Proposal / ProceduralPolicy /
  │                          EditAffordance backing doc / ViewAffordance backing doc)
  ├── SchemaWrapper* ──> schema Document
  │      ├── EditAffordance* ──> edit-definition Document
  │      ├── ViewAffordance* ──> view-definition Document
  │      ├── Board* ──> board-definition Document
  │      └── default_board?
  ├── EventStream* ──ordered──> EventRecord*
  │      └── Meeting? folds one stream and links a meeting Document/Body/Policy
  └── DomainCommit* ──parent──> DomainCommit
         └── DomainCommitDocument* ──> exact Document + Revision + hashes
```

Runtime-only concepts include schema/document cursors, edit/view/board projections, authorization decisions, command envelopes, event data, and meeting projections.

## Capability Matrix

| Proposed concept | Support | Evidence / boundary |
|---|---|---|
| Project or namespace | **Existing** | `Domain` groups documents/event streams, namespaces keys, owns visibility and optional repository history. |
| Source | **Partial** | `ExternalDocument` and `script/import_json.rb` model URL/file origin; no general adapter, credentials, or refresh lifecycle. |
| Append-only Observation | **Partial** | Generic append-only `EventRecord` exists, but no first-class `Observation` type or general observation API; ordinary timeline documents are mutable-by-revision. |
| Historical document revisions | **Existing** | Full immutable revision bodies, parent links, heads, authors/messages; domain commits optionally snapshot exact heads. Restore UI/service is absent. |
| Board/layout | **Existing** | Persisted schema-backed `Board` definitions and runtime projection; `layout` is stored/projected but presently not rendered. |
| Card/presentation | **Partial** | Multiple `ViewAffordance` presentations and UI card primitives exist; there is no persistent generic Card/Panel entity. |
| Schema-defined presentation | **Partial** | Schema wrappers attach JSON-defined edit/view affordances, but renderer implementations and allowlists are hard-coded. |
| Graph/time-series rendering | **Partial** | D3 relative timeline renderer exists; no graph renderer and no generic time-series storage/query/aggregation layer. |
| External API ingestion | **Partial** | CLI URL/file JSON import and origin metadata exist; no routed ingestion API, polling service, or adapter framework. |
| Scheduled refresh | **Missing** | Job infrastructure exists, but recurring configuration only cleans queue records; no source refresh job/schedule was found. |
| Derived metrics | **Partial** | Configured derived indexes and domain-specific projections/tallies exist; no generic metric/formula/aggregation concept. |
| Provenance | **Partial** | Strong event provenance and exact revision links for indexes/commits/proposals exist; no universal configuration-revision lineage for produced documents/data. |

## Likely Implementation Touchpoints

The following existing files/modules are the evidence-based seams likely to be involved if the corresponding missing capabilities are later added; this is an inventory, not an implementation proposal.

- Persistent document/revision concepts: `db/schema.rb`, `app/models/document.rb`, `app/models/revision.rb`, `app/models/draft.rb`, `app/services/publish_draft.rb`, `app/services/documents/diff.rb`, `app/services/domain_commits/create.rb`, `app/services/domain_exports/{export,import}.rb`.
- Schema behavior and reference semantics: `app/models/schema_wrapper.rb`, `app/lib/documents/schema_resolver.rb`, `app/lib/documents/resolved_path.rb`, `app/models/documents/cursor.rb`, `app/models/ptr/*`, `lib/json_ptr.rb`, `app/services/sync_schema_wrapper_for_document.rb`.
- Query/index/derivation: `app/models/document_index_entry.rb`, `app/services/document_indexes/{configured_definitions,rebuild,rebuild_timeline_domain}.rb`, `app/jobs/document_indexes/rebuild_job.rb`, and `app/services/boards/*_collection.rb`.
- Append-only data and provenance: `app/models/event_stream.rb`, `app/models/event_record.rb`, `app/models/events/data.rb`, `app/models/commands/envelope.rb`, `app/services/event_streams/append.rb`, aggregate projection/command services under `app/services/meetings` and `app/services/procedural_policies`.
- Boards/layout/actions: `app/models/board.rb`, `app/models/boards/{schema,body_validator,projection,definitions}.rb`, `app/services/boards/action_resolution.rb`, `app/services/boards/domain_commands/*`, `app/controllers/boards_controller.rb`, `app/controllers/boards/actions_controller.rb`, `app/views/boards/*`, and `config/boards/*.json`.
- Presentations/renderers: `app/models/view_affordance.rb`, `app/models/view_affordances/body_validator.rb`, `app/services/view_affordances/*`, `app/controllers/documents/view_affordances_controller.rb`, `app/controllers/drafts/view_affordance_builders_controller.rb`, `app/views/view_affordances/*`, and `app/javascript/controllers/timeline_view_controller.js`.
- Editor composition: `app/models/edit_affordance.rb`, `app/models/edit_affordances/*`, `app/controllers/drafts/edit_affordance_builders_controller.rb`, `app/controllers/drafts_controller.rb`, and `app/components/drafts/*`.
- External sources, APIs, schedules, and secrets: `app/models/external_document.rb`, `script/import_json.rb`, `config/routes.rb`, `config/recurring.yml`, `app/jobs/application_job.rb`, `config/queue.yml`, `config/credentials.yml.enc`, and `app/controllers/application_controller.rb`.
- Cluster/catalog propagation: `app/services/clusters/catalog.rb`, `app/services/clusters/seed_domain.rb`, `app/services/clusters/sync_installed.rb`, `lib/tasks/clusters.rake`, and cluster-related specs.
