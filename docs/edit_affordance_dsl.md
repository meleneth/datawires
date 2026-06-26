# Edit Affordance DSL

Edit affordances are ordinary JSON documents attached to a `SchemaWrapper`. They describe how to edit schema-backed document drafts. The current format is version `1`.

This document names the current DSL shape. The runtime path is:

1. Raw affordance document JSON
2. Version upgrade through `EditAffordances::Versions`
3. Projection into `EditAffordances::Projection`
4. Rendering by draft editor components
5. Draft mutations, navigation actions, and commit actions

## Top-Level Shape

```json
{
  "version": 1,
  "start_screen": "main",
  "commit_mode": "review_screen",
  "subforms": [],
  "screens": [
    {
      "id": "main",
      "title": "Main",
      "mode": "page",
      "columns": 12,
      "default_span": 4,
      "commit_mode": "review_screen",
      "root_binding": {
        "kind": "document_ptr",
        "ptr": ""
      },
      "rows": []
    }
  ]
}
```

`screens` is the preferred shape for new affordances. Each screen has a stable `id`, optional `title`, optional `root_binding`, and its own row definitions. `start_screen` selects which screen should render first; when omitted, projection starts at the first screen.

The earlier single-screen shape remains supported for compatibility:

```json
{
  "version": 1,
  "screen": {
    "mode": "page",
    "columns": 12,
    "default_span": 4,
    "commit_mode": "review_screen"
  },
  "rows": []
}
```

Legacy `screen`/`rows` documents project as a single screen with id `main`. `rows` is an array of row arrays. Each row contains cell objects. The current renderer supports field cells, navigation cells, and commit cells.

## Field Cells

Field cells bind an editor widget to a document path. If `span` is omitted, projection uses `screen.default_span`.

```json
{
  "binding": {
    "kind": "document_ptr",
    "ptr": "/title"
  },
  "span": 6,
  "widget": "auto",
  "label": true,
  "help": "Use the public display name.",
  "placeholder": "Ada Lovelace",
  "display": {
    "compact": false,
    "readonly": false
  },
  "reference": {
    "schema_key": "person",
    "index_type": "identity",
    "placeholder": "Select person"
  },
  "collection": {
    "behavior": "list_open",
    "presentation": "list",
    "creation": "new_screen",
    "navigation": "open_item",
    "delete": "disabled",
    "reorder": "disabled",
    "item_title": {
      "kind": "property",
      "name": "name"
    },
    "item_subtitle": {
      "kind": "value_label"
    }
  }
}
```

Supported widgets today:

- `array`
- `auto`
- `base64_image`
- `checkbox`
- `number`
- `reference`
- `select`
- `text`
- `textarea`

`auto` lets schema metadata choose the editor. Arrays render through the current collection/list editor.

`base64_image` renders string values as image previews and keeps the underlying value editable as text. Values may be complete `data:image/...;base64,...` URLs or raw base64 payloads; raw payloads are rendered as PNG data URLs.

`reference` renders a select from `DocumentIndexEntry` rows. `reference.schema_key` scopes options to indexed documents of one schema in the current domain. `reference.index_type` defaults to `identity`.

`label` controls whether the field label is shown. `help` renders short guidance beneath the field. `placeholder` is passed to text-like inputs. Required fields are marked from schema metadata during rendering.

`display.compact` tightens spacing and control height for dense forms. `display.readonly` renders an inert value preview instead of an autosaving input.

Array fields may include `collection`. The current supported behavior is `list_open`, represented as separate axes so future collection work can add presentations and workflows without turning collection behavior into one large enum:

- `presentation`: `list`, `table`, or `cards`
- `creation`: `new_screen` or `inline_blank_form`; `append_and_open` is accepted as a compatibility alias for `new_screen`
- `navigation`: currently `open_item`
- `delete`: `disabled` or `enabled`
- `reorder`: `disabled` or `enabled`
- `item_screen`: optional screen id to use when opening an existing or newly-created collection item

Collection item actions currently use regenerated array index paths. After delete or reorder, Hotwire rerenders the collection view with fresh item links.
- `item_title`: optional item label binding, defaulting to the item object `name` property
- `item_subtitle`: optional subtitle binding, defaulting to the item value preview

Collection bindings support `property`, `value_label`, and `none`. A `property` binding needs a `name`.

Schema path metadata is centralized through `SchemaPaths::Inventory`. Generated affordances and projected bespoke fields use inventory entries for widget inference, default labels, and required markers; the structured builder and preview/example generation should use the same inventory source.

## Subforms

Subforms are named, inline row groups stored in the affordance document. They let object screens and collection item screens reuse the same field layout relative to a root binding.

```json
{
  "subforms": [
    {
      "id": "item_fields",
      "rows": [
        [
          {
            "binding": {
              "kind": "document_ptr",
              "ptr": "/name"
            }
          },
          {
            "binding": {
              "kind": "document_ptr",
              "ptr": "/quantity"
            }
          }
        ]
      ]
    }
  ],
  "screens": [
    {
      "id": "item",
      "root_binding": {
        "kind": "document_ptr",
        "ptr": "/items/:index"
      },
      "subform": "item_fields"
    }
  ]
}
```

When a screen references a subform, the subform rows are projected relative to the screen root. In the example above, opening `/items/0` on the `item` screen projects `/name` as `/items/0/name` and `/quantity` as `/items/0/quantity`.

For now, subforms live inline under the top-level `subforms` collection rather than as separate affordance documents.

## Path Variables

Screen root bindings and field bindings may include path variables such as `:index` for collection item screens.

```json
{
  "id": "item",
  "root_binding": {
    "kind": "document_ptr",
    "ptr": "/items/:index"
  },
  "rows": [
    [
      {
        "binding": {
          "kind": "document_ptr",
          "ptr": "/items/:index/name"
        }
      }
    ]
  ]
}
```

When the current draft path is `/items/0`, projection substitutes `:index` with `0`. Collection fields can set `collection.item_screen` to send item links and new-item redirects to this screen.

## Navigation Cells

Navigation cells place a link to another projected screen in the editor.

```json
{
  "kind": "navigation",
  "target_screen": "details",
  "label": "Edit details",
  "span": 4
}
```

`target_screen` must match a screen id when the affordance uses the `screens` collection. If `label` is omitted, projection uses the target screen title and then falls back to `Open`.

## Commit Cells

Commit cells place a commit action in the projected editor. If `span` is omitted, projection uses `screen.default_span`.

```json
{
  "kind": "commit",
  "span": 12,
  "commit_mode": "review_screen",
  "message_mode": "inline_optional"
}
```

`commit_mode` may be declared globally, per screen, or on a commit cell. Projection resolves it in that order from most specific to least specific: commit cell, screen, top-level affordance, legacy `screen.commit_mode`, then `review_screen`.

Supported commit modes:

- `review_screen`: opens the commit review/preflight screen before publishing
- `immediate`: posts the commit directly; if preflight warnings block the commit, the normal review screen is shown

Supported message modes:

- `hidden`
- `inline_optional`
- `inline_required`

The review commit flow renders the draft body diff before publishing. The same `Documents::Diff` rows used by the editor review panel are shown on the commit screen, so authors can confirm changed JSON pointer paths and before/after values before creating the next revision.

## Projection Behavior

`EditAffordance#projection` is the runtime entry point. It returns `EditAffordances::Projection`, whose rows contain typed cells under `EditAffordances::Cells`.

Authoring mode is permissive. Invalid cells become `EditAffordances::Cells::Invalid` entries with diagnostics so the affordance can be repaired.

Runtime mode falls back to the generated editor when a bespoke affordance is invalid, preserving the invariant that a broken affordance must not block document editing.

## Self-Hosting And Recovery

The `edit-form` schema describes edit affordance documents themselves. Seeds create a default edit affordance for that schema, which lets affordance documents be edited with the same bespoke editor model used by ordinary schema-backed documents.

Self-hosting is intentionally layered:

- The structured builder remains available from schema pages for constrained authoring.
- The builder Raw tab edits the affordance draft body directly for repair.
- Runtime projection falls back to the generated editor when a bespoke affordance is invalid.
- The seeded `edit-form` affordance is just another schema-backed document, so changes flow through ordinary draft and commit history.

If the self-hosted affordance breaks, use the schema page builder or raw draft editor for the affordance document, repair the JSON, and commit normally.

## Seeded Fixture Affordances

`Seeds::AffordanceFixtureExamples` creates a small `Affordance Fixtures` domain for manual testing. Each fixture includes a schema document, one example instance document, and one attached edit affordance document:

- `fixture-flat-object`: scalar fields, selects, checkbox, textarea, and review commit
- `fixture-nested-object`: multi-screen navigation into nested object screens with subforms
- `fixture-object-array`: object collection with table presentation, item screen, delete, and reorder
- `fixture-scalar-array`: scalar collection with inline blank creation, delete, and reorder
- `fixture-mixed-workflow`: navigation, object collection item screen, scalar collection, textarea, and commit review in one workflow

Run `bin/rails db:seed` to refresh the fixtures. The seeds are idempotent; repeated runs update the fixture revisions when the schema, example document, or affordance body changes.
