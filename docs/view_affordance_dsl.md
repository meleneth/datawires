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
- `renderer`: required string. `timeline_d3`, `mud_player`, and `mud_choice_player` are currently supported.
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

## MUD Player

`mud_player` renders a read-only room play surface for private MUD-style domains. It resolves the current room from the viewed room document key, a character document's `location_room_key`, a world document's `start_room_key`, or `config.start_room_key`.

Supported config fields:

- `room_schema_key`: room schema document key. Defaults to `mud-room`.
- `character_schema_key`: character schema document key. Defaults to `mud-character`.
- `item_schema_key`: item schema document key. Defaults to `mud-item`.
- `start_room_key`: optional fallback room key.

The room documents are expected to include `name`, `description`, and an `exits` array with `direction`, `label`, `room_key`, and `description`. Character documents use `location_room_key` and optional `inventory_item_keys`. Item documents use `location_kind` and `location_key`.

## MUD Choice Player

`mud_choice_player` renders a read-only PBX-style choice room. It is intended for “three choices, two deaths, one progress path” games such as Wizard's World-style demos. It resolves the current room from the viewed choice-room document key or `config.start_room_key`.

Supported config fields:

- `choice_room_schema_key`: choice-room schema document key. Defaults to `mud-choice-room`.
- `start_room_key`: optional fallback room key.

Choice-room documents are expected to include `name`, `room_type`, `stage`, `prompt`, `terminal_text`, and a `choices` array. Challenge rooms author up to three choices with `label`, `description`, `outcome`, and `target_room_key`. Terminal rooms use `room_type` values of `death` or `victory` and display `terminal_text`.
