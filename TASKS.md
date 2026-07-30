# Task List

This file is now the live working list only. Historical roadmap detail lives in
the commit history.

## Current Focus

Make a first-class **Datawires Board** the normal schema-wrapper landing
experience, then use it as the workspace for a real, eventually complete
Robert's Rules parliamentary procedure engine. Robert's Rules must be expressed
as schema-backed Datawires policy documents and affordances executed by generic
Datawires command, event, projection, authorization, and policy infrastructure;
it must not grow a bespoke Robert's Rules subsystem in the Rails backend. Reach
that destination through narrow, complete vertical slices that use the real
generic architecture from the beginning.

**Invariant:** A broken bespoke affordance must never prevent editing the
document or repairing the affordance.

**Parliamentary invariant:** A proposal is not pending business merely because
it exists, and no procedural state or adopted text may change without an
auditable command/event lineage that can deterministically rebuild the meeting.

## Current State

- [x] Edit affordances are schema-backed documents attached to schemas.
- [x] Bespoke affordances have a generated/raw fallback path.
- [x] The affordance DSL is versioned, validated, projected, documented, and
      covered by diagnostics.
- [x] Runtime editing supports screens, navigation, subforms, collection
      behavior, draft mutation, and commit flow.
- [x] The structured builder can create/edit affordance drafts from schema
      pages.
- [x] The builder supports rows, fields, spans, labels, widgets, help text,
      collection policy, preview, diagnostics, raw JSON, and normal save/commit.
- [x] The builder supports visiting row/field nodes, reordering rows and fields,
      deleting rows/fields, continuing existing drafts, deleting affordances, and
      requiring a row before fields can be added.
- [x] Existing builder cells can be revised through structured forms for fields,
      navigation cells, and commit cells.
- [x] The builder can add navigation and commit cells to existing rows.
- [x] Collection item screen choices are constrained to existing screen ids.
- [x] The builder can add screens and subforms, select the active screen, and
      edit rows through subform-backed screens.
- [x] Reference widgets are selectable from structured add/edit field controls.
- [x] Reference widget schema source and index key options are editable through
      structured controls.
- [x] Collection reference-label title/subtitle bindings are editable through
      structured controls.
- [x] Edit affordance DSL docs describe dynamic references and reference-label
      collection bindings.
- [x] Edit affordance DSL docs describe derived document index definitions.
- [x] Root document index definitions are addable through structured builder
      controls.
- [x] Structured root document indexes can be deleted from the builder.
- [x] Structured index deletion preserves raw JSON positions around invalid
      entries.
- [x] Root document index metadata can be added through structured builder
      controls.
- [x] Root document index metadata strip-prefix transforms can be added through
      structured builder controls.
- [x] Root document index value strip-prefix transforms can be added through
      structured builder controls.
- [x] Root document index keys can bind to root pointers through structured
      builder controls.
- [x] Root document index conditions can be added through structured builder
      controls.
- [x] Array-sourced document indexes can be added through structured builder
      controls.
- [x] Array-sourced document index metadata can bind to item pointers through
      structured builder controls.
- [x] Edit affordance DSL docs describe inline array item row layouts.
- [x] Field compact/read-only display flags are editable through structured
      controls.
- [x] Screen-level commit mode is editable through structured screen controls.
- [x] Top-level start screen and default commit mode are editable through
      structured screen controls.
- [x] Collection append-and-open creation mode is selectable through structured
      controls.
- [x] Screen root pointer and subform assignment are editable through structured
      screen controls.
- [x] Subform root pointers are editable through structured screen controls.
- [x] Screen mode is editable through structured screen controls.
- [x] New domains can be pre-seeded from clusters.
- [x] The first cluster, Worldbuilding Tools, seeds Person, Place, Thing, Party,
      and Timeline Event schemas with default edit affordances.
- [x] Worldbuilding timeline events use relative integer time values, including
      negative values, and include party join/leave event types.
- [x] Add Solid Queue-backed document index rebuild jobs for derived lookup
      metadata after draft commits.
- [x] Add a reference edit widget backed by document index entries.
- [x] Add a Robert's Rules cluster that opts into domain-as-repository mode and
      seeds Agreement, Motion, Proceeding Event, and Meeting State schemas.
- [x] Add service-level domain archive export/import that preserves document
      revisions, schema/edit affordance links, and domain commit parentage.
- [x] Wire domain archive export/import into the UI.
- [x] Add a Robert's Rules service for applying adopted main, extend, amend, and
      close motions to Agreements in one domain commit.
- [x] Wire Robert's Rules motion application into the document UI.
- [x] Split Robert's Rules Motion authoring between new agreement keys and
      target agreement references.
- [x] Split the default Robert's Rules Motion edit affordance into workflow
      screens for details, agreement effect, and result.
- [x] Use reference widgets for Worldbuilding Timeline Event top-level party and
      person links.
- [x] Support custom inline array item fields and use them for Worldbuilding
      Party member person references.
- [x] Support dynamic reference schemas from sibling fields and use them for
      polymorphic Timeline participant references.
- [x] Add runtime view affordances that can render schema-backed documents with
      bespoke read-only presentations.
- [x] Add seeded D3 timeline-style view affordances for Worldbuilding Timeline
      Event and Robert's Rules Proceeding Event documents.
- [x] Add validation and diagnostics for the view affordance DSL.
- [x] Document the current view affordance DSL and timeline renderer config.
- [x] Add a raw view affordance builder so view affordance documents can be
      created, opened, diagnosed, previewed, committed, and deleted.
- [x] View affordance builder deletion removes the affordance and backing draft
      document under request coverage.
- [x] Add structured settings for the first view affordance renderer while
      keeping Raw JSON as the repair path.
- [x] Add structured timeline participant filter settings for view affordance
      drafts.
- [x] Share timeline renderer markup between runtime views and builder previews.
- [x] Resolve timeline participant labels from document identity indexes when
      rendering timeline view affordances.
- [x] Constrain timeline view builder schema selection to domain schemas and
      preview against the configured schema key.
- [x] Add a Playwright e2e harness that boots Rails test, seeds deterministic
      demo data, and cleans up the Windows process tree reliably.
- [x] Add Playwright coverage for playing the Wizard World safe path through
      the three-choice PBX-style view affordance.
- [x] Add Playwright coverage for the schema-suggestion edit affordance builder
      flow: apply a schema suggestion, open the realized field, refine it, and
      verify persistence after reload.
- [x] Fix inline builder field editor labels/ids so Playwright and users can
      target controls by accessible label names.

## Next Major Roadmap: Boards and Parliamentary Procedure

This roadmap supersedes the vague Robert's Rules thrash target below without
discarding the completed prototype work above. The existing Agreement, Motion,
Proceeding Event, and Meeting State schemas and documents are useful evidence
and migration fixtures. The prototype `RobertsRules::ApplyMotion` service and
its hard-coded document UI action have been removed so they cannot become an
accidental second write path. The remaining prototype documents are not the final
parliamentary model: in particular, the existing Motion schema currently mixes
proposal authoring, motion state, and results, while the existing Agreement
schema includes pre-adoption statuses. New work must preserve readable history
and demo data while moving operational writes through the engine. New
Robert's Rules cluster installations no longer seed those prototype schemas or
their bespoke affordances; they seed only the generic engine schemas. Existing
domains retain their stored prototype documents as compatibility data.

The first end-to-end parliamentary release is the vertical slice spanning
Phases 1–11. It must create a body and membership, submit and schedule a
proposal, open a quorate meeting, grant the floor, make/second/rule/debate a main
motion, process one first-degree amendment and both votes, produce an Agreement,
replay the meeting, and expose the result through board and view affordances.
It is not acceptable to implement that path as temporary CRUD to replace later.

### Domain Language and Lineage

- **Proposal:** a schema-backed `Document` submitted before or outside a
  meeting that expresses proposed business. Scheduling makes it available to a
  meeting; it does not put it before the assembly.
- **Motion:** a procedural act made by an actor during a meeting. It may use a
  Proposal as source material, but it records what was actually moved.
- **Pending Question:** the operative question before the assembly. Pending
  questions form a stack; a subsidiary or incidental question can become
  immediately pending while preserving the questions beneath it.
- **Decision:** the recorded procedural disposition of a Pending Question,
  including its rule evaluation and vote/result evidence.
- **Agreement** (or **Resolution** when configured by the schema): the durable,
  authoritative schema-backed `Document` produced by adoption. It is not a
  Proposal with `status: adopted`.
- Preserve explicit lineage from Proposal and its immutable Revision, through
  Motion, amendment operations and intermediate Pending Question versions, to
  Votes, Decision, and the final Agreement Revision. Preserve the exact text or
  structured value presented for every vote.
- Retain **Proceeding Event** as user-facing terminology where useful. Engine
  code may use `MeetingEvent` for the versioned append-only record and project
  those records into Proceeding Event documents/read models rather than
  maintaining two independent histories.

### Architecture Decisions

1. **Board versus view affordance.** A `ViewAffordance` renders one
   schema-backed document. A first-class `Board` is itself an ordinary
   schema-backed meta-document associated with a `SchemaWrapper`, alongside
   edit and view affordances, and composes collections, summaries, actions, and
   navigation into a workspace. Use constrained, versioned, typed section and
   action definitions; do not create a general analytics/query language.
2. **Proposal versus motion.** Proposal submission is document authoring.
   Making a Motion is an in-meeting command by a recognized actor. The Motion
   snapshots or references the exact Proposal Revision used, so later Proposal
   edits cannot rewrite meeting history.
3. **Roles versus capabilities.** A RoleAssignment is a historical,
   effective-dated relationship between an actor and a Body or Meeting
   (member, chair, secretary, temporary chair, parliamentarian). A Capability
   describes what the actor may attempt against a resource. Role policy may
   grant capabilities, but the concepts and APIs remain separate.
4. **Authorization versus procedural validity.** Datawires authorization
   answers an explicit question equivalent to
   `authorization.allowed?(actor:, action:, resource:)`. The parliamentary
   engine separately answers a question equivalent to
   `procedure.in_order?(command:, state:, rules:)`. Controllers, views, and
   Keycloak claims do not duplicate either decision.
5. **Commands and append-only events.** Authenticated actors request explicit
   commands against an expected Meeting revision. Accepted commands append
   versioned events with actor, timestamp, command id/type/payload, evaluated
   rules, rationale, and causation/correlation provenance. Meeting state is a
   projection. Corrections append events; committed history is never silently
   rewritten.
6. **Pending-question stack.** The stack is first-class projected meeting
   state, not a status field on Motion. Stack operations are procedural effects
   of accepted commands; every pushed, replaced, resumed, and disposed question
   is reconstructable.
7. **Keycloak boundary.** Keycloak (currently reached through Keystone and
   oauth2-proxy headers) authenticates the actor and may supply organization
   hints, groups, and broad administrative claims. Datawires stores durable
   actor mappings, Memberships, RoleAssignments, capability policy, and all
   parliamentary decisions. Historical roles remain queryable after identity
   claims change.
8. **Robert's Rules as Datawires policy.** The backend supplies generic typed
   primitives—commands, conditions, actor relationships, stack operations,
   procedural effects, vote requirements, events, decisions, and contextual
   policy evaluation. The Robert's Rules cluster supplies ordinary
   schema-backed policy documents that compose those registered primitives. Do
   not add `RobertsRules::*` handlers, controllers, or hard-coded motion
   branches. Specialized behavior is acceptable only as a reusable,
   domain-neutral Datawires primitive with domain-neutral tests.

### Cross-Phase Engineering Rules

- Follow Rails naming and persistence conventions where they fit; use RSpec,
  FactoryBot, Haml, small cohesive objects, immutable value objects where
  useful, and dependency injection at identity, clock, authorization, rules,
  and persistence boundaries.
- Keep business logic out of controllers and authorization/procedural logic out
  of views. Affordances render engine-provided command descriptions, expected
  effects, prerequisites, and human-readable unavailable reasons.
- Keep Robert's Rules names and defaults in seeded schema-backed policy
  documents, not Ruby conditionals. Generic backend registries expose a small,
  versioned vocabulary of safe operation types; policies select and compose
  them but cannot execute arbitrary code.
- Validate every new meta-document DSL/version as schema-backed data and retain
  the existing permissive authoring/diagnostic/repair pattern used by
  affordances. Generated/raw fallback paths must remain available.
- Treat repository-mode `DomainCommit` history as a useful domain-wide
  integrity layer, not as a substitute for ordered Meeting events or
  optimistic concurrency on a single Meeting stream.
- Prefer deterministic unit tests for policies, rules, commands, effects, and
  projections; request/integration tests for complete paths; replay tests from
  the full event stream; authorization matrices; schema validation tests; and
  focused Playwright coverage for critical operational journeys.
- Do not add a rules DSL, event-sourcing framework, workflow engine, policy gem,
  or query framework unless a later implementation proposal demonstrates a
  concrete limitation in the existing Rails/application architecture.

### Phase 1 — Datawires Board Foundation

**Purpose:** Make a schema-level workspace, rather than the schema workshop,
the normal entry point for domain users.

**Dependencies:** Completed `SchemaWrapper`, schema-backed revision,
`EditAffordance`, `ViewAffordance`, document index, and builder diagnostic work.

**Tasks and introduced objects/schemas:**

- [ ] Add a `Datawires Board` meta-schema and a singular `Board` record attached
      to a `SchemaWrapper` through its schema-backed board document, mirroring
      established affordance ownership and revision conventions.
- [ ] Add an explicit optional default-board association on `SchemaWrapper`;
      validate that the selected Board belongs to that wrapper and provide a
      deterministic fallback when no default is selected.
- [ ] Define version 1 typed board projections for title, description, ordered
      sections, and layout metadata. Initially support document-collection,
      projection-backed meeting/proposal collections, and summary sections
      only.
- [ ] Constrain collection definitions to schema key, typed filters, typed
      ordering, result limit, result `ViewAffordance`, empty-state copy, and
      navigation target. Reuse document indexes where applicable.
- [ ] Define typed board actions that either open an `EditAffordance` to create
      a document or invoke a registered domain command. Unknown section/action
      kinds must diagnose safely rather than execute.
- [ ] Add capability descriptors for section visibility and action
      visibility/availability; evaluation is server-side and unavailable
      reasons survive projection.
- [ ] Add create/open/diagnose/preview/commit/delete authoring paths with raw
      JSON repair access and a generated fallback board.
- [ ] Prefer the default Board on normal `SchemaWrapper`/domain landing routes;
      retain explicit links to schemas and meta-level edit/view/board tooling
      for authorized authors and administrators.

**Invariants:**

- A Board composes multiple documents; it never masquerades as a
  `ViewAffordance`.
- Board definitions are data, but only registered typed filters, orderings,
  navigation targets, and actions may execute.
- Capability filtering cannot be bypassed by guessing a board action URL.
- An invalid or deleted Board cannot block access to documents or meta-tools.

**Acceptance criteria and RSpec expectations:**

- Model/validator/version/projection specs cover valid and invalid sections,
  actions, layouts, limits, affordance references, and diagnostics.
- Authorization specs prove hidden, disabled-with-reason, and available states
  and prove action endpoints reauthorize.
- Request specs prove default-board landing and meta-tool escape hatches.
- Query/service specs prove stable filtering, ordering, limits, empty states,
  and no cross-domain/schema leakage.
- A focused Playwright path creates/repairs a Board and lands on it after
  commit.

**Non-goals:** arbitrary joins, expressions, aggregations, user-authored SQL,
dashboard charting, cross-domain analytics, and drag-and-drop layout design.

### Phase 2 — Identity Claims and Domain Actor Boundary

**Purpose:** Normalize authenticated identity without allowing Keycloak or
transport headers to become domain policy.

**Dependencies:** Phase 1 capability hooks may initially deny by default or use
the existing `User#can?` seam; complete this phase before operational Board
actions.

**Tasks and introduced objects/schemas:**

- [ ] Introduce an `Actor` domain value/adapter over the existing `User` and
      Keystone/oauth2-proxy identity fields; persist stable issuer/subject
      linkage and retain existing user ids.
- [ ] Normalize trusted identity claims into an immutable request snapshot with
      issuer, subject, organization hints, groups, and broad admin claims.
- [ ] Define a Datawires authorization interface returning an explicit
      allow/deny decision and reason; adapt the current `Authorization` concern
      and `User#can?` without spreading new direct role conditionals.
- [ ] Record the authenticated actor identity and relevant claim snapshot or
      reference in command provenance without treating claims as historical
      RoleAssignments.
- [ ] Specify fail-closed behavior for missing, conflicting, or untrusted claim
      sources and issuer/subject remapping.

**Invariants:**

- Authentication claims identify an actor; they do not decide whether a motion
  is in order or prove historical body membership.
- Domain authorization is injectable and independently testable.
- The same external subject cannot silently become two Datawires actors within
  an issuer.

**Acceptance criteria and RSpec expectations:**

- Unit/request specs cover claim normalization, stable mapping, conflicts,
  missing claims, logout-compatible existing behavior, and authorization
  decision reasons.
- Contract specs prove controllers call the authorization boundary and do not
  inspect Keycloak groups for parliamentary decisions.

**Non-goals:** administering Keycloak, synchronizing every realm object,
delegated identity, impersonation, or a general ABAC language.

### Phase 3 — Bodies, Memberships, and Scoped Role Assignments

**Purpose:** Represent durable parliamentary relationships and capability
grants in Datawires.

**Dependencies:** Phase 2.

**Tasks and introduced objects/schemas:**

- [ ] Add schema-backed `Body` documents and domain records/read models for
      `Membership` and `RoleAssignment`, scoped to a Body or Meeting.
- [ ] Support actor, role, scope, effective start/end, status, and provenance;
      seed typed roles for member, chair, secretary, temporary chair, and
      parliamentarian without hard-coding their policy in views.
- [x] Add capability policies for submitting proposals, creating/opening
      meetings, recording minutes, voting, chair actions, and administering
      Board definitions.
- [ ] Define effective-at-time queries so event replay resolves the historical
      assignment in force at the event timestamp/revision.
- [ ] Add authorized Board/edit flows to create a Body, establish membership,
      and assign scoped meeting roles.

**Invariants:**

- Roles are contextual relationships; capabilities are evaluated operations.
- Ending a Membership or RoleAssignment does not erase it or alter prior
  commands/events.
- Meeting-scoped assignments override or supplement Body assignments only
  through explicit policy.

**Acceptance criteria and RSpec expectations:**

- Model/schema specs cover scopes, effective ranges, provenance, overlap rules,
  and historical queries.
- Policy matrix specs cover each initial role/capability combination, denial
  reasons, scope isolation, and effective dates.
- Request specs cover authorized lifecycle operations and reject cross-body
  role use.

**Non-goals:** committees/sub-bodies, proxies, weighted membership, elections,
dues, or automatic Keycloak group-to-role synchronization.

### Phase 4 — Datawires Command, Event, and Policy Infrastructure

**Purpose:** Establish the generic permanent write path, typed policy evaluator,
and immutable procedural history before adding Robert's Rules policy.

**Dependencies:** Phases 2–3 and existing immutable `Revision`/repository-mode
`DomainCommit` work.

**Tasks and introduced objects/schemas:**

- [x] Add a typed command envelope with command id, type/version, Meeting id,
      expected stream revision, actor, timestamp, payload, correlation id, and
      causation id.
- [ ] Add append-only, monotonically sequenced `MeetingEvent` records with
      event type/version/payload plus command, actor, timestamp, authorization
      decision, procedural rule evaluation, rationale, and authority
      provenance.
- [ ] Add a command bus/handler boundary that authenticates, authorizes,
      loads/rebuilds state, evaluates procedure, appends events atomically, and
      returns typed success/conflict/rejection results.
- [x] Add schema-backed, versioned Datawires policy documents and a
      fail-closed evaluator for registered conditions and procedural effects.
      Policies compose typed values; they do not name or execute Ruby classes.
- [ ] Define the initial domain-neutral primitive registry for state
      conditions, role/capability predicates, stack effects, lifecycle effects,
      vote requirements, and event templates, validating every primitive's
      input/output contract.
- [ ] Add registries/upcasters for command and event versions; reject unknown
      future versions safely and test old-version replay fixtures.
- [ ] Add explicit correction/supersession event primitives. Prohibit update or
      delete of committed event payloads through application APIs.
- [ ] Coordinate resulting schema-backed document Revisions and
      `DomainCommit`s without treating either as the Meeting stream sequence.

**Invariants:**

- Rejected commands append no state-changing events, while their rejection may
  be recorded in a separate audit channel if policy requires.
- A command id is idempotent within a Meeting stream.
- Event order, payload, and provenance are sufficient for deterministic replay.
- No controller or CRUD callback directly mutates operational Meeting state.
- No command handler branches on the Robert's Rules cluster, a named Robert's
  Rules motion, or a Robert's Rules schema key; behavior comes from evaluated
  policy and registered generic primitive effects.

**Acceptance criteria and RSpec expectations:**

- Command-handler contract specs cover authorization, procedural rejection,
  idempotency, atomic append, provenance, unknown versions, and handler errors.
- Policy schema/evaluator specs cover composition, unknown primitives, invalid
  inputs, deterministic output, unsafe references, and fail-closed behavior.
- Persistence specs prove append-only behavior and sequence uniqueness.
- Version fixture specs replay at least one prior event version through an
  upcaster.
- Integration specs prove event append and related domain commit either both
  succeed or fail without a partially advanced operational projection.

**Non-goals:** Kafka, distributed event buses, cross-service sagas, arbitrary
event subscriptions, replacing Datawires document Revisions, a general-purpose
rules language, or Robert's Rules-specific backend handlers.

### Phase 5 — Meeting Projection and Optimistic Concurrency

**Purpose:** Make current Meeting state a deterministic projection serialized
against a known stream revision.

**Dependencies:** Phase 4.

**Tasks and introduced objects/schemas:**

- [x] Add a schema-backed `Meeting` document for identity, Body, schedule,
      agenda/proposal references, and lifecycle metadata; keep derived
      procedural state out of mutable document fields.
- [x] Implement initial commands/events for schedule meeting, open meeting,
      establish attendance, establish quorum, and adjourn meeting.
- [ ] Build a `MeetingProjection` containing stream revision, lifecycle,
      attendance/electorate inputs, quorum finding, roles in force, floor,
      pending-question stack, debate, and vote state.
- [x] Atomically compare the command's expected revision while appending;
      return a conflict with the new revision/projection rather than silently
      rebasing simultaneous commands.
- [x] Add deterministic full replay and optional discardable checkpoints;
      checkpoints must be invalidatable and never be the sole source of truth.

**Invariants:**

- Projection output depends only on the ordered event stream, versioned rule
  inputs explicitly referenced by events, and deterministic projectors.
- Only one command can advance a Meeting from a given expected revision.
- Quorum findings identify the attendance/electorate snapshot and rule used.

**Acceptance criteria and RSpec expectations:**

- Projection unit specs cover every initial event and lifecycle transition.
- Replay specs rebuild byte-equivalent normalized state from the complete
  stream and from checkpoint-plus-tail.
- Concurrency specs submit two commands at one expected revision and prove only
  one advances the stream.
- Integration specs cover schedule/open/quorum/adjourn and failure recovery.

**Non-goals:** offline merge, multi-leader streams, automatic quorum-loss
effects beyond initial explicit findings, or full agenda/minutes management.

### Phase 6 — Recognition and Floor Control

**Purpose:** Treat recognition and control of the floor as explicit procedural
state.

**Dependencies:** Phase 5 and scoped meeting roles from Phase 3.

**Tasks and introduced objects/schemas:**

- [ ] Add commands/events equivalent to request recognition, recognize member,
      relinquish/end floor, and record an authorized interrupting action.
- [ ] Project recognition requests, current floor holder, purpose/reason the
      floor was granted, reason/time it ended, and debate participation history.
- [ ] Add typed speaking-limit and alternating-debate policies with Robert's
      Rules defaults supplied by the cluster's policy documents and contextual
      evaluation by the generic Datawires evaluator; record the policy version
      and result used.
- [x] Distinguish general capability to seek/make a motion from current
      procedural prerequisites such as recognition and another actor holding
      the floor.
- [x] Expose available, prerequisite-needed, and unavailable commands with
      reasons and expected effects.

**Invariants:**

- At most one actor holds the floor.
- Granting or ending the floor is evented and serialized against Meeting
  revision.
- Only defined interrupting actions bypass ordinary recognition requirements.

**Acceptance criteria and RSpec expectations:**

- Rule/unit specs cover eligibility, queueing, one floor holder, interruption,
  speaking limits, alternating preference, and clear denial reasons.
- Replay/concurrency specs prove the floor cannot be double-granted.
- Request/component specs prove UI renders engine command descriptions rather
  than reimplementing recognition rules.

**Non-goals:** automated speech transcription, timers that autonomously append
events, remote hand-raising transport, or every preference rule.

### Phase 7 — Proposals, Motions, and Pending-Question Stack

**Purpose:** Introduce the central domain boundaries and a real main-motion
path.

**Dependencies:** Phases 3–6.

**Tasks and introduced objects/schemas:**

- [x] Add a dedicated Proposal schema and submission lifecycle outside Meeting
      procedure; record author, Body, submitted immutable Revision, title,
      structured content, and scheduling lineage.
- [ ] Migrate/compatibly interpret existing prototype Motion documents so new
      `Motion` records represent procedural acts, not pre-meeting proposals.
- [ ] Add typed main-motion commands/events for make, second, rule in order,
      rule out of order, open debate, close debate when permitted, and withdraw
      when permitted.
- [ ] Add first-class `PendingQuestion` identity/version/projection and stack
      effects for push, make immediately pending, update text version, dispose,
      and resume the question beneath.
- [ ] Define schema-backed motion policy documents whose generic projections
      answer questions equivalent to `in_order?`, `debatable?`, `amendable?`,
      `vote_requirement`, and `effect`; metadata alone or a precedence integer
      is insufficient.
- [ ] Begin a small mechanics vocabulary: command, condition, procedural rule,
      pending question, procedural effect, vote requirement, actor
      relationship, event, and decision.
- [ ] Seed the initial main-motion Robert's Rules policy by composing those
      mechanics; document data, not a `RobertsRules::MainMotion` class or case
      statement, defines the supported behavior.

**Invariants:**

- A Proposal never enters the pending stack without a successful make-motion
  command.
- Motion-as-made snapshots/references the Proposal Revision and exact content
  moved.
- Seconding and chair rulings are events, not Motion status edits.
- The stack always has one immediately pending top or is empty; questions below
  retain identity and version.
- The same generic command/policy evaluator executes every motion type; named
  Robert's Rules types exist in policy documents, not backend subclasses.

**Acceptance criteria and RSpec expectations:**

- Schema/model specs prove Proposal/Motion separation and immutable source
  lineage.
- Command/rule specs cover recognition, capability, second requirements,
  in/out-of-order rulings, debate opening, and stack transitions.
- Replay specs reconstruct the stack and exact question text at each revision.
- Integration specs cover proposal scheduling through debated main motion and
  prove merely creating/scheduling a Proposal does not create pending business.

**Non-goals:** all motion families, informal agenda consent, committees,
renewability beyond the initial main motion, automated parliamentary advice,
or a bespoke Ruby object hierarchy for Robert's Rules motions.

### Phase 8 — Structured First-Degree Amendment

**Purpose:** Apply one real amendment without destructive edits and prove that
schema-backed documents can preserve adopted-text lineage.

**Dependencies:** Phase 7.

**Tasks and introduced objects/schemas:**

- [ ] Add immutable `DocumentRevisionRef`, `AmendmentOperation`, and
      `PendingQuestionVersion` value/schema types.
- [ ] Support typed operations for insert, strike, replace, substitute, divide,
      and structured-value modification, with schema path/document node as the
      preferred target and textual range as a validated fallback.
- [x] Implement the initial vertical slice with one first-degree amendment and
      the minimal operation(s) needed by its fixture; keep the remaining
      operation shapes validatable or explicitly future-versioned rather than
      pretending to execute them.
- [x] Add move-amendment and rule-amendment-in/out-of-order commands/events,
      pushing the amendment question and preserving the main question beneath.
- [x] Materialize deterministic intermediate text/value and retain original
      Proposal content, each operation, pre/post versions, and vote-presented
      version.
- [x] On amendment disposition, resume the original or amended main question
      without mutating its prior versions.

**Invariants:**

- Amendments never destructively edit the Proposal or a prior pending version.
- Every operation names an immutable base revision/version and fails with a
  reason if its target is ambiguous or stale.
- Adopted amendment effects are deterministic and schema-valid for the target
  question.

**Acceptance criteria and RSpec expectations:**

- Value-object/schema specs cover paths, nodes, ranges, operation validation,
  stale bases, invalid targets, and structured schema validation.
- Property/example specs prove deterministic application and preservation of
  originals/intermediates.
- Stack/replay specs cover pushing, disposing, and resuming the amended main
  question.
- Integration fixture demonstrates a first-degree amendment whose adopted
  final text materially differs from the submitted Proposal.

**Non-goals:** second-degree amendments, amendment-to-substitute edge cases,
editor conflict UX, arbitrary rich-text operational transforms, or semantic
natural-language amendment parsing.

### Phase 9 — Voting Subsystem Foundation

**Purpose:** Model votes independently so later parliamentary methods and
threshold rules remain possible.

**Dependencies:** Phases 3, 5, 7, and 8.

**Tasks and introduced objects/schemas:**

- [ ] Add `Vote`, `ElectorateSnapshot`, `Ballot/CastVote`, `VoteRequirement`,
      and `VoteResult` types with immutable links to Meeting revision and the
      exact PendingQuestionVersion presented.
- [x] Implement commands/events equivalent to open vote, cast vote, change vote
      where initially permitted, close vote, and announce/certify result.
- [ ] Initial vertical slice: attributable counted yes/no/abstain voting with
      explicit electorate snapshot, attendance/eligibility, quorum basis,
      threshold basis, chair/tie rule, totals, and certification.
- [ ] Reserve typed voting method and ballot-attribution modes for voice,
      rising, roll call, secret ballot, unanimous consent, and later additions
      without forcing every method into per-member `VoteCast` events.
- [ ] Separate collection/closure from result announcement and support explicit
      challenge/correction events rather than result mutation.

**Invariants:**

- Eligibility is evaluated against the frozen electorate/attendance snapshot,
  not current membership at read time.
- One effective ballot per eligible actor unless a rule permits and records a
  change.
- The threshold states its basis (votes cast, members present, entire
  membership, or another typed basis); abstentions are never silently assigned
  a meaning.
- Secret methods must not claim secrecy while storing attributable public
  ballot events.

**Acceptance criteria and RSpec expectations:**

- Rule/unit specs cover eligibility, duplicate/change behavior, abstentions,
  quorum, majority threshold basis, ties, and chair eligibility.
- Command/concurrency specs cover simultaneous final ballots and close-vote
  conflicts.
- Replay specs reproduce electorate, effective ballots, totals, requirement,
  and certified result.
- Integration specs vote on the amendment and main motion using their exact
  question versions.

**Non-goals:** cryptographic ballots, every voting method, proxies, weighted
votes, cumulative voting, and external election-provider integration.

### Phase 10 — Decision and Agreement Production

**Purpose:** Convert a disposed question into an auditable Decision and, when
adopted, a durable authoritative Agreement.

**Dependencies:** Phases 7–9 and existing Agreement/domain-commit work.

**Tasks and introduced objects/schemas:**

- [ ] Add a `Decision` schema/model with PendingQuestionVersion, Vote/result or
      unanimous-consent evidence, disposition, authority/rule evaluation,
      announcement, and correction lineage.
- [x] Produce an Agreement/Resolution document only from an adopted main
      question's final structured version; link its first immutable Revision to
      Proposal, Motion, amendments, Vote(s), and Decision.
- [ ] Refine the existing Agreement schema so pre-adoption Proposal states do
      not make Agreement the proposal lifecycle; migrate or compatibly render
      existing demo documents.
- [x] Retire `RobertsRules::ApplyMotion` and its hard-coded document UI action;
      existing prototype documents remain readable, but there is no direct
      operational write path to preserve.
- [ ] Port only its still-valid semantics into schema-backed policies composed
      from generic Datawires effects; no UI may mark a Motion adopted and
      directly apply it.
- [ ] Commit coordinated Agreement, Decision, and read-model changes in
      repository mode while retaining Meeting event sequence as procedural
      truth.

**Invariants:**

- Final adopted content is the disposed PendingQuestionVersion, not whatever
  text currently appears on the source Proposal.
- A Decision records rejection or other disposition even when no Agreement is
  produced.
- Agreement corrections/supersession use new revisions and explicit lineage.

**Acceptance criteria and RSpec expectations:**

- Schema/service specs prove complete lineage and exact adopted content.
- Atomicity/idempotency specs prove event retry cannot create duplicate
  Agreements or Decisions.
- Compatibility specs keep completed Robert's Rules demo/history readable.
- End-to-end integration spec completes steps 1–18 of the initial vertical
  slice and rebuilds the same Meeting, Decision, and Agreement references from
  events.

**Non-goals:** codification/publication workflows, signatures, legal
enforceability, agreement execution tracking, or bulk migration of unrelated
domains.

### Phase 11 — Robert's Rules Operational Board

**Purpose:** Turn the Board into the normal cockpit for upcoming business and
active procedure.

**Dependencies:** Phases 1–10.

**Tasks and introduced objects/schemas:**

- [x] Store the initial Body workspace layout, collection constraints, limits,
      navigation, and action command names in a versioned Board definition
      document loaded as data rather than constructing a Robert-specific Board
      in Ruby.
- [x] Add a constrained meeting-collection section that selects and orders
      Meeting documents by policy-derived projection status without embedding
      Robert's Rules event names or lifecycle transitions in Board Ruby code.
- [x] Add a constrained proposal-collection section that derives open/decided
      state from durable Decision lineage without mutating Proposal documents
      or interpreting policy-specific dispositions in Board Ruby code.
- [x] Seed a default Robert's Rules Board titled `Datawires Board` (or a
      domain-specific title derived from it) with active/upcoming Meeting, open
      Proposals, last 10 adopted Agreements, and last 5 completed Meetings.
- [ ] Add capability-aware actions to create a Meeting and submit a Proposal;
      actions open the appropriate edit affordance or registered domain
      command rather than generic schema internals.
- [ ] Navigate every listed item to its appropriate `ViewAffordance` or
      operational Meeting screen.
- [ ] For an active Meeting, project current Pending Question, complete stack,
      floor holder, debate state, Vote state, and actor-specific available,
      prerequisite-needed, and unavailable commands with reasons/effects.
- [ ] Prefer this Board on the Robert's Rules schema/domain landing experience;
      keep repository history and schema/edit/view/board authoring reachable to
      actors with meta-level capabilities.
- [ ] Display the resulting Agreement and its procedural lineage using a
      dedicated view affordance.

**Invariants:**

- Board/view components render engine results and never independently infer
  parliamentary legality or authorization.
- Collection counts/order/limits are deterministic: exactly the requested last
  10 adopted Agreements and last 5 completed Meetings at most.
- Normal domain users land in the workspace, not a list of schema internals.

**Acceptance criteria and RSpec expectations:**

- Board projection/request specs cover all collections, limits, empty states,
  navigation, default landing, and capability combinations.
- Component specs cover active Meeting state and command reason/effect display.
- A Playwright scenario performs steps 1–19 of the initial vertical slice
  through real Board/affordance/command endpoints and verifies the Agreement
  view after a fresh replay/reload.

**Non-goals:** general analytics, configurable parliamentary reports, full
minutes authoring, or pixel-complete mobile control-room design.

### Phase 12 — Chair Rulings, Appeals, and Correction Events

**Purpose:** Keep the engine usable and auditable where automation is
incomplete or a ruling is contested.

**Dependencies:** Phases 4–11.

**Tasks and introduced objects/schemas:**

- [ ] Add explicit commands/events for ruling an action in/out of order,
      rationale, governing authority citation, issuing a chair ruling, and
      appealing it.
- [ ] Model the appeal as a Pending Question where applicable and record the
      Decision sustaining or overturning the chair.
- [ ] Add typed correction events for factual/event metadata and projected
      procedural state, each identifying the erroneous event/state, rationale,
      authority, expected effect, and correcting actor.
- [ ] Add explicit unanimous-consent commands/events with request, opportunity
      to object, objection, and adoption paths.
- [ ] Add a typed “record unsupported procedural action” path whose known
      effect is explicit and reviewable; never expose a generic hidden
      force-state mutation.

**Invariants:**

- Chair authority is capability- and scope-checked and every override remains
  visible in replay and UI.
- Corrections supersede or compensate; they do not edit historical events.
- Unknown effects cannot silently alter projected state.

**Acceptance criteria and RSpec expectations:**

- Command/rule/replay specs cover rulings, appeal stack behavior, sustain/
  overturn Decisions, unanimous consent, corrections, and unsupported actions.
- Authorization specs distinguish chair, temporary chair, parliamentarian,
  member, and administrator.
- Integration specs prove a corrected replay and an appealed ruling retain the
  original history and rationale.

**Non-goals:** automatic adjudication of every point of order or an unrestricted
administrator state editor.

### Phase 13 — Additional Motion Families and Precedence

**Purpose:** Expand from the vertical slice through reusable parliamentary
mechanics rather than isolated mini-frameworks.

**Dependencies:** Phases 7–12.

**Tasks and introduced objects/schemas:**

- [ ] Implement typed precedence/context rules and interrupt/renewability
      conditions; precedence metadata may inform evaluation but is never the
      sole legality rule.
- [ ] Add motion families incrementally, each as a complete command-event-rule-
      stack-vote-decision-UI slice: selected subsidiary motions first, then
      privileged, incidental, and motions that bring a question again before
      the assembly.
- [ ] Prioritize mechanics needed for commit/postpone/refer, limit/close debate,
      lay on/take from table, recess/adjourn, point of order, reconsider,
      rescind/amend something previously adopted, division, and requests.
- [ ] Encode named motion types as schema-backed policies composed from shared
      conditions, effects, vote requirements, and actor relationships. When
      composition cannot express a rule clearly, add the smallest reusable
      domain-neutral Datawires primitive rather than a motion-specific backend
      object.
- [ ] Track when a motion may interrupt, requires a second, is debatable,
      amendable, renewable, reconsiderable, and what question/effect it targets
      through contextual methods.

**Invariants:**

- Adding a motion type cannot bypass the command/event pipeline or stack.
- Context-sensitive behavior is evaluated from state/rules, not flattened to
  static booleans or one precedence number.
- Every implemented motion family has a complete disposition and replay path.
- A policy package for another parliamentary authority can reuse the backend
  without loading or branching through Robert's Rules code.

**Acceptance criteria and RSpec expectations:**

- Table-driven rule specs cover precedence against every already-supported top
  question, recognition/interruption, debate/amendment, renewability, and vote
  requirements.
- Integration/replay specs cover at least one adopted and rejected path per new
  family plus return to the preserved question beneath.
- UI contract specs prove command availability and reasons come from the
  engine.

**Non-goals:** implementing the entire parliamentary authority in one release,
generating motion behavior from a universal DSL, or adding one Ruby
class/service per named Robert's Rules motion.

### Phase 14 — Organization-Specific Procedural Rules

**Purpose:** Apply governing authority in explicit layers with narrow,
testable extension points.

**Dependencies:** Stable mechanics from Phases 3–13.

**Tasks and introduced objects/schemas:**

- [ ] Add versioned typed policy sets for applicable law, charter, bylaws,
      special rules of order, standing rules, adopted parliamentary authority,
      meeting-specific adopted overrides, and established custom.
- [ ] Define deterministic authority priority, applicability dates/scopes,
      citations, conflict diagnostics, and provenance recorded with each rule
      evaluation.
- [ ] Expand the schema-backed Robert's Rules policy package and explicit
      organization configuration for supported extension points such as
      quorum, speaking limits, motion variants, vote thresholds, and chair
      voting; the generic evaluator remains authority-agnostic.
- [ ] Add Meeting commands/events to adopt or end supported meeting-specific
      overrides; replay references the immutable policy versions in effect.
- [ ] Diagnose unsupported/conflicting rules and route them through visible
      chair rulings rather than interpreting arbitrary prose.

**Invariants:**

- Historical replay uses the rule versions in force then, not today's
  organization configuration.
- Higher-authority rules override lower layers only through explicit,
  inspectable resolution.
- Configuration cannot execute arbitrary Ruby or silently redefine event
  semantics.

**Acceptance criteria and RSpec expectations:**

- Policy resolution specs cover every authority layer, dates/scopes,
  conflicts, citations, defaults, and Meeting overrides.
- Replay fixtures prove later bylaw/config changes do not change past outcomes.
- Schema/authorization specs cover safe authoring and administration.

**Non-goals:** a general-purpose rules DSL, natural-language rule execution,
legal interpretation, or support for every organization's custom rule shape.

### Phase 15 — Expanded Voting Methods

**Purpose:** Extend the voting foundation without weakening electorate,
threshold, secrecy, or audit guarantees.

**Dependencies:** Phases 9, 12, and 14.

**Tasks and introduced objects/schemas:**

- [ ] Add voice, rising, roll-call, ballot, and unanimous-consent strategies as
      distinct typed collection/certification flows.
- [ ] Add secret-versus-attributable storage and display policies, with
      aggregate procedural events for secret methods and separately protected
      ballot material when retention is required.
- [ ] Expand eligibility, chair-voting, tie, vote-change, challenge,
      recertification, and correction rules by contextual policy.
- [ ] Support additional threshold bases and methods without changing prior
      Vote event semantics.
- [ ] Surface method-appropriate controls and audit views through operational
      affordances.

**Invariants:**

- A method's evidence and privacy model are explicit; a voice vote is not
  represented as fabricated individual ballots.
- Certification records who certified, the rule/threshold, evidence summary,
  challenges, and corrections.
- Historical result display respects ballot secrecy and domain capabilities.

**Acceptance criteria and RSpec expectations:**

- Strategy contract specs share electorate/requirement assertions while testing
  method-specific evidence and privacy.
- Authorization/privacy specs prove secret ballot attribution is not leaked by
  Board, view, export, logs, or ordinary event payloads.
- Integration/replay specs cover every method, ties, challenge, and corrected
  certification.

**Non-goals:** public-election scale, end-to-end cryptographic voting,
third-party election vendors, or jurisdiction-specific statutory certification.

### Phase 16 — Replay, Audit, Import, and Resilience Tooling

**Purpose:** Make complete procedural history operable, verifiable, portable,
and recoverable.

**Dependencies:** All event and policy formats intended for the first stable
release; builds on existing domain archive export/import.

**Tasks and introduced objects/schemas:**

- [ ] Add commands/tasks to rebuild one/all Meeting projections, compare stored
      projections/checkpoints, and report the first divergence without changing
      history.
- [ ] Add an audit timeline joining commands, authorization decisions, rule
      evaluations, events, Pending Question versions, Votes, Decisions,
      Agreement Revisions, corrections, and DomainCommits.
- [ ] Extend domain archives with event streams, version manifests, integrity
      hashes, actor/role/rule references, and deterministic import validation.
- [ ] Add dry-run import, idempotent retry, partial/corrupt archive rejection,
      old-version upcasting, and explicit unsupported-version reports.
- [ ] Add operational metrics/logging for conflicts, rejected commands,
      projection lag/failure, replay divergence, and event upcast failures
      without leaking secret ballots or sensitive claims.
- [ ] Add disaster-recovery and upgrade runbooks with representative immutable
      event-stream fixtures.

**Invariants:**

- Full event streams plus referenced immutable rule/document versions are
  sufficient to reconstruct procedural state and lineage.
- Import never rewrites colliding history or silently skips unknown events.
- Repair tooling emits correction events or rebuilds discardable projections;
  it never mutates authoritative event payloads.

**Acceptance criteria and RSpec expectations:**

- Golden-stream tests rebuild complete meetings from every supported event
  version and compare normalized projection digests.
- Export/import round-trip specs preserve ids, order, hashes, lineage,
  provenance, secrecy boundaries, and DomainCommit parentage.
- Corruption, collision, retry, checkpoint loss, and interrupted-rebuild tests
  demonstrate safe recovery.
- A CI documentation/runbook check exercises the supported audit and replay
  commands against a deterministic fixture.

**Non-goals:** multi-region active/active operation, a blockchain, a generic
event-store product, or indefinite support for unversioned development
fixtures.

### Open Questions

Only these choices require evidence or policy beyond the current repository;
they do not block the early phases:

- Which edition/source of the adopted parliamentary authority may Datawires
  encode and distribute, and what citation/licensing constraints apply to rule
  text and explanatory UI? Keep mechanics and organization configuration
  source-agnostic until this is settled.
- What retention, encryption, access, and export policy is required for secret
  ballot material? Phase 9 must preserve a compatible abstraction, but Phase 15
  cannot choose storage details without the deployment's governance policy.
- Is “Agreement” the universal adopted-document term, or should each Body select
  among Agreement, Resolution, and other schema-backed output types? Keep
  `Agreement` as the repository's current default and make output type an
  explicit later policy rather than renaming existing work now.

## Ongoing Affordance and Quality Backlog

- [x] Add Playwright coverage for authoring-side affordance creation from a
      schema page: create an edit affordance, drive the builder, commit it, and
      use the resulting affordance on a document.
- [x] Add a Wizard World death-path Playwright test that chooses a wrong option
      and verifies the terminal failure room has no onward choices.
- [ ] Add Playwright coverage for creating/refining a view affordance in the
      structured view builder once the next renderer shape is clear.
- [ ] Expand the structured view affordance builder as additional renderer
      shapes become clear from use.
- [x] Add affordance support for rendering base64-encoded strings as images.
- [x] Add a general domain-as-repository mode where domain commits form a
      parent-linked, tamper-evident history over the conceptual full domain
      state.
- [ ] Improve Robert's Rules authoring through the phased engine roadmap above
      as real meeting traces expose rough edges; do not extend the prototype
      CRUD workflow as a parallel procedural model.
- [ ] Add generated examples/documents for worldbuilding clusters if manual use
      shows empty domains are too sparse.
- [ ] Keep every new builder affordance reachable, reversible, and repairable.
- [ ] Prefer constrained wins over broad abstractions until the missing shapes
      are obvious from use.
