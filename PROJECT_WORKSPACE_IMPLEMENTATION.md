# Project Workspace Implementation

## Scope

Implement a major private-project capability expansion using `Domain` as the project boundary and versioned Datawires documents as configuration. `ProjectAffordance` is additive: it must coexist with, and must not promote, replace, adapt, subsume, or reinterpret, domain-home, `DomainHomeLinks`, edit affordances, view affordances, boards, or application-specific affordances.

## Decisions

- `ProjectAffordance` is a new first-class affordance type: a one-to-one domain wrapper referencing its own separate versioned document and core schema. Its document owns project-specific title, description, navigation, workspace policy, and authoring configuration; the wrapper may identify a default project board. It does not reuse `domain-home` and does not change the meaning of any existing affordance.
- A domain can host any combination of `ProjectAffordance`, domain-home, edit/view affordances, boards, and application-specific affordances. Domains without a project affordance retain exactly the legacy domain experience.
- General board composition remains versioned-document based but gains an extensible layout model. Boards support multiple layouts (kanban, grid/dashboard, list, and future registered layouts), ordered regions/columns, and reusable card definitions without encoding presentation kinds in controllers.
- Cards are versioned presentation nodes that can target documents, queries, metrics, graphs, actions, and forms. Card resolution goes through registered card handlers with a common result contract; boards compose cards while view affordances continue to present individual schema-backed documents independently.
- Presentation becomes provider-based: renderer descriptors register validators, projection builders, templates/components, and optional client controllers. Graph renderers consume a normalized series/graph projection so line, sparkline, and later graph types do not require controller case statements.
- `Source` is a domain-scoped runtime wrapper around a separate versioned source-configuration document. Source adapter providers own configuration validation, execution, normalization, health/status mapping, and retry classification. HTTP/JSON is the first adapter, not a hard-coded terminal design.
- Credentials are separate encrypted/runtime records referenced by source configuration identifiers; secrets never enter versioned document bodies, observations, logs, archives, or provenance. Authorization gates credential use and management.
- Source lifecycle covers draft/publish, enable/disable, manual runs, polling schedules, leases/concurrency, timeout, retry/backoff, run records, status/health, and adapter version. Scheduled dispatch discovers due sources and enqueues executions; manual and scheduled runs share one execution pipeline.
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

Work performed under the mistaken domain-home promotion assumption has **not been committed**. It currently includes:

- `Projects::Install` selecting the existing `domain-home` document as the project document and changing its schema.
- `DomainHomeLinks` preferring the project-affordance document.
- `Clusters::SeedDomain` automatically installing project affordances by promoting cluster home documents.
- Project-affordance tests that assert promotion/reuse of `domain-home`.

These changes conflict with the corrected architecture and must be removed or rewritten before implementation continues. The additive `ProjectAffordance` migration/model/schema/validator work may be retained only after its associations and tests are made independent of domain-home.

## Phases

1. **Architectural correction** — remove the uncommitted domain-home promotion behavior; retain only independent project-affordance foundations. Status: completed.
2. **Project identity and authoring** — independent schema/document/wrapper, creation UI/service, project navigation and settings editing, legacy-domain compatibility, archive coverage. Status: foundation implemented; archive coverage remains.
3. **Provider infrastructure** — common registries/contracts for cards, layouts, sources, queries/aggregates, renderers, and archive contributors. Status: base registry and card/layout registration implemented; remaining provider contracts pending.
4. **General boards and cards** — multi-layout board DSL and authoring; document, view, query, metric, graph, action, and form card providers. Status: compatible columns and kanban/grid/list layouts implemented with document/action/form providers; query/metric/graph providers and authoring UI pending.
5. **Sources and operations** — source/credential/run models, HTTP/JSON adapter, manual runs, polling, leases, retries/backoff, status UI, provenance. Status: source/config, encrypted credentials, runs, HTTP/JSON provider, manual/scheduled jobs, retry policy, and basic status UI implemented; credential UI and stronger distributed leases pending.
6. **Typed observations and metrics** — immutable observations, corrections, metric metadata/dimensions, aggregation/time bucketing, derived metrics, rollups, lineage. Status: typed immutable observations with configuration/run/adapter provenance implemented; correction/query/metric layers pending.
7. **Generalized queries and rendering** — normalized scalar/table/series/graph projections; statistic, sparkline, line, and extensible graph renderers. Status: pending.
8. **Project-native configuration UI** — integrated project, board/card, source/credential, metric/query, run/status authoring flows. Status: pending.
9. **Archive and compatibility completion** — export/import contributors, format migration, cluster/demo compatibility, operational-data policy. Status: pending.
10. **Validation and handoff** — focused/full tests, style/security checks, migration and extension documentation, remaining production gaps. Status: pending.

## Test Results

- Migration `20260825000001` was applied to the disposable test database.
- Corrected project-affordance and legacy compatibility suite: 26 examples, 0 failures, 12 pre-existing scaffold pendings.
- Board provider/layout/card compatibility suite: 24 examples, 0 failures.
- Source/credential/execution/observation suite: 4 examples, 0 failures; request/scheduler coverage pending execution.

## Remaining Gaps

- Project-affordance archive/export/import coverage remains.
- Provider, board/card, source, observation/metric/query/rendering, and project-native authoring phases remain.
