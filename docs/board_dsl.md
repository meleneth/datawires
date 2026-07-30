# Datawires Board DSL

Boards are schema-backed workspace documents associated with a `SchemaWrapper`.
A board composes collections and actions across documents; it does not replace a
`ViewAffordance`, which renders one document.

The current format is version `1`:

```json
{
  "version": 1,
  "title": "Datawires Board",
  "description": "Current business",
  "layout": { "columns": 1 },
  "sections": [],
  "actions": []
}
```

## Document collections

A `document_collection` section selects documents belonging to one schema in
the board's domain:

```json
{
  "id": "open-proposals",
  "kind": "document_collection",
  "title": "Open proposals",
  "description": "Business submitted for a future meeting.",
  "config": {
    "schema_key": "proposal",
    "filters": [
      { "path": "/status", "operator": "eq", "value": "open" }
    ],
    "order": { "by": "updated_at", "direction": "desc" },
    "limit": 10,
    "empty_state": "No open proposals.",
    "navigation": "document"
  }
}
```

Version 1 deliberately supports only:

- equality filters against JSON Pointer paths;
- ordering by `title`, `key`, `created_at`, `updated_at`, or a body value;
- `asc` or `desc` direction;
- limits from 1 through 100, defaulting to 20;
- navigation to the document or a named view affordance.

View-affordance navigation uses:

```json
{
  "navigation": "view_affordance",
  "view_affordance": "Summary"
}
```

The selected view affordance must belong to the collection's schema wrapper.
Missing schemas and affordances render visible configuration errors rather than
falling back to a cross-domain lookup.

Boards do not accept arbitrary queries, expressions, SQL, or executable code.
Additional filters and ordering modes should be introduced as typed,
versioned operations with validator and query coverage.

## Actions

An `open_edit_affordance` action creates a document from a schema and opens its
draft. A named edit affordance is optional:

```json
{
  "id": "submit-proposal",
  "kind": "open_edit_affordance",
  "title": "Submit proposal",
  "config": {
    "schema_key": "proposal",
    "edit_affordance": "Submit",
    "when_denied": "disabled"
  }
}
```

`when_denied` is either `disabled` (the default) or `hidden`. Availability is
resolved on the server and denied actions include a human-readable reason.
Execution resolves and authorizes the action again; a rendered action is never
treated as proof of authorization.

The version 1 shape also reserves typed command actions:

```json
{
  "id": "open-meeting",
  "kind": "invoke_command",
  "title": "Open meeting",
  "config": {
    "command": "open_meeting"
  }
}
```

Command actions remain unavailable until the generic Datawires command
registry exists. Board data cannot name controllers, services, or Ruby classes.
