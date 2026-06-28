# View Affordance DSL

View affordances are schema-backed documents that describe read-only document presentations. The raw builder edits this JSON directly, and the structured builder exposes constrained settings for supported renderers.

```json
{
  "version": 1,
  "renderer": "timeline_d3",
  "title": "Timeline",
  "config": {
    "schema_key": "timeline-event",
    "relative_time_label": "Relative time",
    "participant_kind": "person",
    "participant_key": "ada"
  }
}
```

## Top-Level Fields

- `version`: required integer. Version `1` is currently supported.
- `renderer`: required string. `timeline_d3` is currently supported.
- `title`: optional string used as the rendered view title.
- `config`: optional renderer-specific object.

Invalid view affordance bodies report diagnostics in the builder. Runtime rendering falls back to an unsupported-renderer message rather than blocking document access.

## Timeline D3

`timeline_d3` renders documents from a timeline schema as ordered event data for the shared D3 timeline partial.

Supported config fields:

- `schema_key`: schema document key for timeline events. When omitted, the viewed document schema key is used by the builder, and runtime projection falls back to `timeline-event`.
- `relative_time_label`: label for the timeline axis. Defaults to `Relative time`.
- `participant_kind`: optional schema key used to filter timeline events through participant indexes.
- `participant_key`: optional participant document key override. When `participant_kind` is present and `participant_key` is blank, runtime projection uses the currently viewed document key.

Timeline events are schema-backed documents whose bodies include:

- `relative_time`: numeric position used for ordering and timeline placement.
- `title`: event label.
- `summary`: optional event detail text.
- `participants`: optional array of objects with `kind`, `key`, and optional `role`.

Participant labels resolve through document identity indexes when available, falling back to the participant key.
