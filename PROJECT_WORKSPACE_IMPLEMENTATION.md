# Project Workspace Implementation

## Scope

Implement a major private-project capability expansion using `Domain` as the project boundary and versioned Datawires documents as configuration. `ProjectAffordance` is additive: it must coexist with, and must not promote, replace, adapt, subsume, or reinterpret, domain-home, `DomainHomeLinks`, edit affordances, view affordances, boards, or application-specific affordances.

Production follow-up: new-domain authoring now exposes Project workspace as an independent selection alongside the existing cluster/application selector. Selecting it installs the versioned project affordance during domain creation; leaving it clear preserves legacy behavior, and it can be combined with any cluster.

## Decisions

- `ProjectAffordance` is a new first-class affordance type: a one-to-one domain wrapper referencing its own separate versioned document and core schema. Its document owns project-specific title, description, navigation, workspace policy, and authoring configuration; the wrapper may identify a default project board. It does not reuse `domain-home` and does not change the meaning of any existing affordance.
- A domain can host any combination of `ProjectAffordance`, domain-home, edit/view affordances, boards, and application-specific affordances. Domains without a project affordance retain exactly the legacy domain experience.
- General board composition remains versioned-document based but gains an extensible layout model. Boards support multiple layouts (kanban, grid/dashboard, list, and future registered layouts), ordered regions/columns, and reusable card definitions without encoding presentation kinds in controllers.
- Cards are versioned presentation nodes that can target documents, queries, metrics, graphs, actions, and forms. Card resolution goes through registered card handlers with a common result contract; boards compose cards while view affordances continue to present individual schema-backed documents independently.
- Presentation becomes provider-based: renderer descriptors register validators, projection builders, templates/components, and optional client controllers. Graph renderers consume a normalized series/graph projection so line, sparkline, and later graph types do not require controller case statements.
- `Source` is a domain-scoped runtime wrapper around a separate versioned source-configuration document. Source adapter providers own configuration validation, execution, normalization, health/status mapping, and retry classification. HTTP/JSON is the first adapter, not a hard-coded terminal design.
- Credentials are separate encrypted/runtime records referenced by source configuration identifiers; secrets never enter versioned document bodies, observations, logs, archives, or provenance. Authorization gates credential use and management.
- Source lifecycle covers draft/publish, enable/disable, manual runs, polling schedules, leases/concurrency, timeout, retry/backoff, run records, status/health, and adapter version. Scheduled dispatch discovers due sources and enqueues executions; manual and scheduled runs share one execution pipeline. HTTP execution rejects private/reserved resolved addresses by default; operators may explicitly allow hosts with `DATAWIRES_SOURCE_ALLOWED_HOSTS`.
- `Observation` is an append-only typed data plane. Every observation points to source, source configuration revision, source run, adapter/version, observation type/schema, observed/effective/recorded times, dimensions, value/payload, units/metric identity, and provenance. Mutations are prohibited; corrections append superseding/retracting observations.
- Metric definitions and derived metrics are versioned documents. Metric metadata includes identity, type, unit, dimensions, aggregation semantics, time field, correction policy, and retention/rollup hints. Query execution supports dimension filters/grouping, time windows and bucketing, count/sum/min/max/average/last and extensible aggregates, correction resolution, derived expressions, and materialized rollups tied to exact definition revisions.
- Query definitions may be embedded in cards or stored as separately versioned query documents. A provider-based query engine returns normalized tables/scalars/series with lineage identifying observation IDs, source/config revisions, metric/query definition revisions, rollup inputs, and execution time.
- Project-native authoring covers project settings, project navigation, board/layout/card editing, source configuration and credentials, run controls/status, metric/query definitions, and renderer selection. All meaningful configuration editing uses drafts and revisions; operational state remains in runtime records.
- Domain archive/export/import expands with versioned format migrations and provider hooks. It covers project wrappers, boards/cards, sources/config revisions (without secret material), credential references, source runs as optional operational history, observations/provenance, metric/query definitions, and extension-owned payloads. Import validates referential integrity before committing.
- Extension points use provider registries discovered through Rails configuration/initializers, with explicit interfaces and capability descriptors. Controllers dispatch through services/providers and do not grow adapter/card/renderer/query `case` statements.

## Complete Destination Architecture

### Configuration plane

- `Domain` remains namespace, ownership, visibility, documents, schemas, event streams, and optional repository history.
- `ProjectAffordance` references a dedicated project-affordance document and optional default project board.
- `Board` references a board document containing layout and card composition; card definitions reference document/view/edit affordances, query/metric definitions, actions, or forms.
- `Source`, metric definitions, query definitions, derived metrics, and renderer settings reference separate versioned documents and retain immutable revision identity at execution.

### Operational and observation plane

- `SourceRun` records trigger, schedule/manual actor, configuration revision, adapter/version, attempts, timing, status, error classification, and counters.
- `SourceCredential` stores encrypted secret material and metadata separately from documents; archives contain references/requirements only.
- `Observation` is immutable and typed; correction links append replacement/retraction facts. Rollups are append-only derived observations with complete input/query/definition lineage.
- Scheduler dispatch and execution jobs use leases and idempotency keys to prevent duplicate concurrent polling while allowing safe retries.

### Composition and provider boundaries

- Card providers: validate configuration, resolve authorization/dependencies, and return normalized card projections.
- Layout providers: validate board layout data and render ordered card regions.
- Source adapter providers: validate, fetch, normalize, classify failures, and expose health capabilities.
- Query/aggregate providers: compile definitions and return scalar/table/series results plus lineage.
- Presentation/graph renderer providers: validate renderer configuration and render normalized projections.
- Archive contributors: export/import extension records with format/version and dependency declarations.

Provider registrations are centralized configuration, not scattered constants or controller branches. Unknown providers produce explicit unavailable projections and diagnostics rather than crashing a board.

## Correction Record

An early uncommitted draft incorrectly promoted `domain-home` into the project affordance. That draft was discarded before the first project-workspace commit. The committed implementation uses a dedicated `project-affordance` document and leaves `domain-home`, `DomainHomeLinks`, edit/view affordances, boards, clusters, and application-specific affordances independent. Compatibility tests enforce that separation.

## Phases

1. **Architectural correction** — remove the uncommitted domain-home promotion behavior; retain only independent project-affordance foundations. Status: completed.
2. **Project identity and authoring** — independent schema/document/wrapper, creation UI/service, project navigation and settings editing, legacy-domain compatibility, archive coverage. Status: completed, including archive v3 round-trip and legacy-domain compatibility.
3. **Provider infrastructure** — common registries/contracts for cards, layouts, sections, sources, queries/aggregates, derived operations, renderers, and archive contributors. Status: completed; runtime dispatch is provider-based and board controllers no longer branch on section kinds.
4. **General boards and cards** — multi-layout board DSL and authoring; document, view, query, metric, graph, action, and form card providers. Status: completed for the first release, including kanban/grid/list layouts, provider-specific configuration fields, accessible move controls, and drag-and-drop column/card ordering with revision history.
5. **Sources and operations** — source/credential/run models, HTTP/JSON adapter, manual runs, polling, leases, retries/backoff, status UI, provenance. Status: completed for the first release. Credentials support encrypted creation, rotation, revocation and source assignment; execution uses expiring leases, idempotent recovery, retry states, and DNS-pinned validated HTTP connections.
6. **Typed observations and metrics** — immutable observations, corrections, metric metadata/dimensions, aggregation/time bucketing, derived metrics, rollups, lineage. Status: completed for the first release. Derived arithmetic operations and aggregates are provider-dispatched; rollups append observations with exact input and metric-definition revision lineage.
7. **Generalized queries and rendering** — normalized scalar/table/series/graph projections; statistic, sparkline, line, and extensible graph renderers. Status: completed for the first release with reusable versioned queries and line, sparkline, area, and bar renderers sharing the normalized series projection.
8. **Project-native configuration UI** — integrated project, board/card, source/credential, metric/query, run/status authoring flows. Status: completed for the first release, including versioned definition drafts and project-native credential, metric, query, source, board, card, renderer, and run controls.
9. **Archive and compatibility completion** — export/import contributors, format migration, cluster/demo compatibility, operational-data policy. Status: completed as archive v4. It round-trips queries and all prior workspace records, supports generic versioned extension contributors, offers full or configuration-only exports, excludes secrets, and imports archive v2/v3/v4.
10. **Validation and handoff** — focused/full tests, style/security checks, migration and extension documentation, remaining production gaps. Status: completed; RSpec, full Playwright, focused RuboCop, Zeitwerk, migration, compatibility, archive and security-boundary checks pass.

## Test Results

- Migration `20260825000001` was applied to the disposable test database.
- Corrected project-affordance and legacy compatibility suite: 26 examples, 0 failures at the phase checkpoint; the later quality pass removed all scaffold pendings.
- Board provider/layout/card compatibility suite: 24 examples, 0 failures.
- Source/credential/execution/observation suite: 4 examples, 0 failures at the phase checkpoint; request, scheduler, failure, network-policy, and provenance coverage was added later.
- Correction/query/graph/archive focused suite: 6 examples, 0 failures.
- Project-native authoring and compatibility suite: 12 examples, 0 failures.
- Source network-policy and row-locked scheduler suite: 5 examples, 0 failures.
- Full RSpec suite after capability completion: 657 examples, 0 failures, 0 pending. Line coverage 88.86%; branch coverage 72.69% (the denominator grew with the new authoring, lease, archive and derived-metric runtime paths).
- Test-quality pass enabled verifying doubled constant names, retained verified partial doubles, introduced no plain doubles/spies, and replaced 12 inert scaffold pendings with six active domain lifecycle examples. Compact branch matrices cover project navigation/configuration, HTTP source behavior, source failure/provenance, observation aggregates, board/policy validation, pointer boundaries, and draft mutation failures.
- Zeitwerk eager-load check: passed.
- RuboCop over all changed handwritten Ruby files: passed; generated `db/schema.rb` retains the repository's existing bracket-style offenses and was not manually reformatted.
- Playwright: 6 browser examples, 0 failures, including project credential/metric authoring, graph presentation, full/configuration-only archive downloads, edit-affordance authoring, and the existing Wizard World flows.

## Release Boundary

The planned first usable project-workspace release is implemented. Further adapters, derived operations, graph families, aggregate providers, card kinds and archive contributors are extensions through the registered provider boundaries rather than known architectural gaps. Production deployment and migration are intentionally not performed by this implementation branch.
