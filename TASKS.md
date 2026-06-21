# Task List

## Edit Affordance Roadmap

The next major design goal is to make bespoke editing experiences for schema-backed JSON documents. An edit affordance should describe both layout and workflow: what fields appear together, how collections are edited, what opens into another screen, and how a draft reaches review/commit.

Keep affordances as ordinary schema-backed documents, but avoid making the affordance editor fully self-referential too early. Build a constrained authoring experience first, then let it grow into its own affordance once the concepts are stable.

**Invariant:** A broken bespoke affordance must never prevent editing the document or repairing the affordance.

Architecture path:

- [ ] Raw affordance document JSON.
- [x] Schema validation.
- [ ] Compatibility/version upgrade.
- [x] Projection into an immutable editor model.
- [ ] Rendering by components.
- [ ] Emission of draft mutations, navigation actions, and commit actions.

## Current Baseline

- [x] Store bespoke edit affordances as documents attached to a `SchemaWrapper`.
- [x] Provide a generated fallback edit affordance for schema-backed documents without a bespoke affordance.
- [x] Project simple rows, fields, labels, spans, widgets, and commit cells from an affordance body.
- [x] Bind fields to document JSON pointers.
- [x] Render arrays as openable item lists.
- [x] Add array items by seeding from item schema and navigating to the new item screen.
- [x] Prepare the test database during devcontainer startup.

## Phase 1: Stabilize DSL, Versioning, Projection, And Diagnostics

- [x] Rename or document the current JSON format as the first edit affordance DSL.
- [x] Keep affordance documents versioned with an explicit `version`.
- [x] Add compatibility handling for older affordance versions.
- [x] Add an upgrade entry point, even while only one version exists.
- [x] Expand the `edit-form` schema to include all currently accepted runtime values, including collection widgets.
- [x] Add schema validation for edit affordance document bodies before they can be attached to a schema.
- [x] Introduce an internal projected edit model separate from raw affordance JSON.
- [x] Add `EditAffordances::Projection` with screens, rows, cells, bindings, defaults, and diagnostics.
- [x] Split projected cells into value objects such as `EditAffordances::Cells::Field`, `Section`, `Array`, `Commit`, and `Invalid`.
- [x] Add tests for projecting multi-field rows, object sections, array cells, commit cells, and invalid cells.
- [x] In authoring mode, project invalid cells into diagnostics and inert invalid cells so affordances can be repaired.
- [x] In runtime mode, fall back to generated/raw editing when a bespoke affordance is invalid.
- [x] Add projection diagnostics so authoring errors can be shown in the UI.
- [x] Add `SchemaPaths::Inventory` as an early service for schema path discovery.
- [ ] Use `SchemaPaths::Inventory` for generated fallback affordances, builder field picking, diagnostics, widget inference, required markers, default labels, and later preview/example generation.

## Phase 2: Improve Single-Screen Forms

- [ ] Support field help text, placeholder text, and required markers.
- [x] Support `textarea`, `select`, `checkbox`, `number`, `text`, and `auto` consistently in both schema and runtime.
- [ ] Add field-level display options such as hidden label, compact width, and read-only/value preview.
- [x] Honor `screen.default_span` when a cell span is omitted.
- [ ] Add tests for required optional blank behavior in the projected editor UI.
- [ ] Review autosave and review-panel updates for all widget types.

## Phase 3: Model Collection Editing

- [ ] Add explicit `collection` config to array field cells.
- [ ] Avoid modeling collection behavior as one large enum; split it into presentation, creation behavior, navigation behavior, delete policy, reorder policy, and item title/subtitle bindings.
- [ ] Support the current behavior as `list_open`.
- [ ] Add `new_screen` behavior for collections that should create an item and navigate to its own screen.
- [ ] Add `inline_blank_form` behavior for collections that should show a new-item form in place.
- [ ] Add `table` presentation for collections of small scalar/object records.
- [ ] Add `cards` or `list_cards` presentation for richer repeated objects.
- [ ] Add item title and subtitle bindings, defaulting to `name` when present.
- [ ] Decide a stable item identity strategy before exposing destructive collection controls, because index-addressed item screens are fragile when reorder/delete exists.
- [ ] Add delete and reorder policy controls only after stable item identity is settled.
- [ ] Add request/component coverage for each collection presentation and behavior.

## Phase 4: Add Screens And Navigation

- [ ] Replace the single implicit screen with a `screens` collection while preserving compatibility with current `screen`/`rows`.
- [ ] Add screen ids, titles, root bindings, and row definitions.
- [ ] Add navigation actions between screens.
- [ ] Add affordance-level start screen selection.
- [ ] Add path variables for screens rooted at collection items, such as `/items/:index`.
- [ ] Support commit behavior per screen or globally.
- [ ] Add route/controller tests for screen navigation and item-screen navigation.

## Phase 5: Add Subforms And Rooted Reuse

- [ ] Introduce named subforms for object fields and collection item objects.
- [ ] Let a subform declare its own rows relative to a root binding.
- [ ] Allow collection item screens to reuse a named subform.
- [ ] Decide whether subforms live inline in the affordance document or as separate affordance documents.
- [ ] Add projection tests for nested object and collection-item roots.

## Phase 6: Build The Structured Affordance Authoring UI

- [ ] Add a way to create an edit affordance for a schema from the schema page.
- [ ] Start with a structured builder, not raw JSON-only editing.
- [ ] Let authors add rows and fields by selecting from schema paths.
- [ ] Let authors configure spans, labels, widget type, and help text.
- [ ] Let authors configure collection policy and item title/subtitle bindings.
- [ ] Show a live preview against a draft or seeded example document.
- [ ] Show projection diagnostics and schema validation errors inline.
- [ ] Keep a raw JSON editor/escape hatch so bad affordance documents can be repaired.
- [ ] Save affordance changes through the normal draft/commit flow.

## Phase 7: Let Affordance Authoring Become Bespoke

- [ ] Create a bespoke edit affordance for the `edit-form` schema after the builder concepts are stable.
- [ ] Use that affordance to author ordinary affordances, but preserve the generated/raw fallback.
- [ ] Add guardrails so a broken affordance editor never blocks repairing affordances.
- [ ] Document the self-hosting path and the fallback recovery path.

## Fixtures And Documentation

- [ ] Add fixture affordances for a flat object.
- [ ] Add fixture affordances for a nested object.
- [ ] Add fixture affordances for an object array.
- [ ] Add fixture affordances for a scalar array.
- [ ] Add fixture affordances for a mixed workflow.
- [ ] Improve commit review so users understand what the affordance changed in the draft body.
- [ ] Add developer docs for the affordance DSL once collection editing stabilizes.
