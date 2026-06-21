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
  "screen": {
    "mode": "page",
    "columns": 12,
    "default_span": 4,
    "commit_mode": "review_screen"
  },
  "rows": []
}
```

`rows` is an array of row arrays. Each row contains cell objects. The current renderer supports field cells and commit cells.

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
  "collection": {
    "behavior": "list_open",
    "presentation": "list",
    "creation": "append_and_open",
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
- `checkbox`
- `number`
- `select`
- `text`
- `textarea`

`auto` lets schema metadata choose the editor. Arrays render through the current collection/list editor.

`label` controls whether the field label is shown. `help` renders short guidance beneath the field. `placeholder` is passed to text-like inputs. Required fields are marked from schema metadata during rendering.

`display.compact` tightens spacing and control height for dense forms. `display.readonly` renders an inert value preview instead of an autosaving input.

Array fields may include `collection`. The current supported behavior is `list_open`, represented as separate axes so future collection work can add presentations and workflows without turning collection behavior into one large enum:

- `presentation`: `list`, `table`, or `cards`
- `creation`: currently `append_and_open`
- `navigation`: currently `open_item`
- `delete`: currently `disabled`
- `reorder`: currently `disabled`
- `item_title`: optional item label binding, defaulting to the item object `name` property
- `item_subtitle`: optional subtitle binding, defaulting to the item value preview

Collection bindings support `property`, `value_label`, and `none`. A `property` binding needs a `name`.

## Commit Cells

Commit cells place a commit action in the projected editor. If `span` is omitted, projection uses `screen.default_span`.

```json
{
  "kind": "commit",
  "span": 12,
  "message_mode": "inline_optional"
}
```

Supported message modes:

- `hidden`
- `inline_optional`
- `inline_required`

## Projection Behavior

`EditAffordance#projection` is the runtime entry point. It returns `EditAffordances::Projection`, whose rows contain typed cells under `EditAffordances::Cells`.

Authoring mode is permissive. Invalid cells become `EditAffordances::Cells::Invalid` entries with diagnostics so the affordance can be repaired.

Runtime mode falls back to the generated editor when a bespoke affordance is invalid, preserving the invariant that a broken affordance must not block document editing.
