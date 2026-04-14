We are rebuilding the Datawires draft editor around Cursor + EditAffordance and want clean, long-lived Rails code.

Architecture rules:
- Documents::Cursor is the location object. It wraps `source` + `path`.
- Cursor navigation is persistent/immutable-style: `at`, `child`, and `parent` return new Cursor objects.
- Cursor is schema-aware enough for convenience methods like `ptr`, `value`, `schema_node`, `children`, `input_kind`, `field_value`, `checkbox_value`, `array?`, `object?`, `scalar?`, etc.
- EditAffordance is the persisted JSON document that defines form layout.
- EditAffordance owns projection. It interprets affordance JSON and produces projected rows/cells.
- Projection objects like `EditForms::ProjectedRow`, `ProjectedField`, and `ProjectedCommit` are dumb render-shape data, not interpreters.
- Drafts::ShowPage is the page/view-model object for Drafts#show.
- ViewComponents should own render assembly. HAML should be thin.

Critical rendering rules:
- NEVER instantiate components in HAML. No `Component.new(...)` in templates.
- If a HAML file contains `.new(`, that is a bug.
- Child component construction belongs in the ViewComponent Ruby class, exposed through methods like `projected_rows_component`, `rendered_component_for(cell)`, `item_cards`, etc.
- HAML should only do things like:
  - `= render some_component_method`
  - plain markup
  - simple conditionals/loops over already-prepared data
- Avoid giant multiline HAML argument lists. Push branching and argument construction into Ruby methods on the component.

Editor behavior rules:
- Scalar field autosave is non-navigational.
- Scalar autosave should not rerender or replace the form/input being edited.
- The editor surface should remain stable during autosave so text cursor position is preserved.
- Structural edits like array add/remove are a separate path and may rerender the editor.
- Review/diff is a separate reactive surface from the editor.

Hotwire/Turbo rules:
- Prefer stable container/frame shells and update inner contents.
- Remember the important distinction:
  - `broadcast_replace_to` replaces the whole target element
  - `broadcast_update_to` updates the target element’s contents
- For the review panel, we want to preserve the frame/container and update its contents.
- `turbo_stream_from` is used directly in HAML, never wrapped in `render`.

Coding/style rules:
- Prefer components over partial sprawl for editor UI.
- Prefer one page object or component input over many loose locals.
- Keep controller code lean: build page object, perform mutation, redirect/respond.
- Keep affordance interpretation out of views and out of projected data objects.
- We prefer rspec, factory_bot, haml, and well-factored code.
- This is intricate, not complicated: solve by clarifying seams, not by adding magic.
- validating mocks is the preferred testing methodology.  Verify collaborator's interfaces, but do not actually run the collaborators

When proposing code:
- Follow the architecture above.
- Keep HAML extremely simple.
- Put branching, child component selection, input method selection, and option building in Ruby methods on the component.
- Do not regress into old partial-based editor assumptions.
