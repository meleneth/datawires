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
