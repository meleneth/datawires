# Task List

This file is now the live working list only. Historical roadmap detail lives in
the commit history.

## Current Focus

Keep shaping the edit affordance builder through hands-on use. Optimize for
small, practical wins that make the builder easier to thrash, repair, and trust.

**Invariant:** A broken bespoke affordance must never prevent editing the
document or repairing the affordance.

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

## Next Thrash Targets

- [ ] Use the builder to author or revise a real edit affordance and capture the
      next rough edges here.
- [x] Add affordance support for rendering base64-encoded strings as images.
- [x] Add a general domain-as-repository mode where domain commits form a
      parent-linked, tamper-evident history over the conceptual full domain
      state.
- [ ] Keep improving Robert's Rules authoring once real meeting traces expose
      rough edges.
- [ ] Add generated examples/documents for worldbuilding clusters if manual use
      shows empty domains are too sparse.
- [ ] Keep every new builder affordance reachable, reversible, and repairable.
- [ ] Prefer constrained wins over broad abstractions until the missing shapes
      are obvious from use.
