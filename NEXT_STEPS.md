# Design the Next Structured View Affordance

Use the prompt below with ChatGPT from the root of the Datawires repository.

---

You are collaborating with me on Datawires, a Ruby on Rails application for
editing and presenting JSON documents through schema-backed affordances. Your
job in this session is to facilitate the design decisions for the next
structured view-affordance renderer and produce an implementation-ready brief.
Do not start coding until the design has converged and I explicitly approve the
brief.

Begin by reading the repository guidance and current implementation, especially:

- `AGENT.md`
- `TASKS.md`
- `docs/view_affordance_dsl.md`
- `docs/edit_affordance_dsl.md`
- `app/models/view_affordances/body_validator.rb`
- `app/services/view_affordances/projection.rb`
- `app/services/view_affordances/*_projection.rb`
- `app/controllers/drafts/view_affordance_builders_controller.rb`
- `app/views/drafts/view_affordance_builders/show.html.haml`
- `app/views/view_affordances/`
- relevant request, model, and Playwright specs

Treat the code as the source of truth. Briefly correct any stale assumptions in
this prompt before beginning the design conversation.

## Current Context

View affordances are schema-backed documents describing read-only
presentations. Their JSON bodies currently use:

```json
{
  "version": 1,
  "renderer": "timeline_d3",
  "title": "Timeline",
  "config": {}
}
```

The supported renderers are currently:

- `timeline_d3`
- `mud_player`
- `mud_choice_player`

The structured builder exposes renderer-specific settings, preview,
diagnostics, commit, and deletion. Raw JSON must remain available as the repair
path. Invalid or unsupported affordances must not block access to documents.
Runtime projections should produce render-shape data; Haml partials should
render that data without becoming interpreters.

The next tracked work is to choose and implement another useful renderer shape,
expand the structured builder for it, and add Playwright coverage for creating
and refining a view affordance through the UI.

## How to Facilitate the Session

Walk through the decisions below in order. Ask no more than three closely
related questions at a time. For each decision:

1. Explain why it matters in plain language.
2. Present two or three concrete options grounded in the existing application.
3. Recommend one option and state its tradeoffs.
4. Wait for my answer before locking the decision.
5. Maintain a visible decision log, including unresolved questions.

Do not accept vague answers when they would leave incompatible implementation
paths open. Use small example documents, projected data, or wireframes when
they materially clarify a choice. Prefer a narrow renderer that solves a real
presentation problem over a generic page-layout framework.

## Decisions to Reach

### 1. User Problem and Example Domain

Identify the actual read-only task the renderer should improve:

- Who is viewing the document?
- What question are they trying to answer?
- Which existing schema and seeded domain provide the first real example?
- Why are the existing timeline and MUD renderers insufficient?
- What is the smallest successful presentation?

If there is no compelling existing example, compare likely candidates such as
a detail card, a collection/table, a grouped summary, or a repository-history
view. Do not choose solely because a renderer is technically convenient.

### 2. Renderer Boundary

Decide whether the renderer presents:

- one document;
- a collection of documents sharing a schema;
- one document plus referenced/indexed documents; or
- a domain-level aggregate.

Clarify which data comes from the viewed document, which comes from its schema,
and which may be resolved through document indexes or references. Define what
must remain deterministic and bounded so rendering cannot become an arbitrary
query language.

### 3. Presentation Shape

Agree on the visible hierarchy and responsive behavior:

- title, subtitle, metadata, sections, rows, cards, or columns;
- ordering and grouping rules;
- labels versus raw values;
- treatment of arrays, nested objects, booleans, blanks, and long text;
- reference labels and links;
- empty, partial, invalid, and missing-reference states;
- narrow-screen and keyboard behavior.

Produce a compact text wireframe for the chosen shape.

### 4. Configuration DSL

Design the smallest renderer-specific `config` object. For every proposed key,
record:

- name and JSON type;
- required or optional;
- default;
- allowed values or pointer constraints;
- validation error;
- runtime fallback;
- corresponding structured-builder control.

Decide whether values bind through JSON Pointers, schema inventory entries,
document-index definitions, literal values, or a deliberately smaller binding
model. Avoid adding a general expression language.

Determine whether version `1` can safely contain the new renderer or whether a
DSL version change is required. Preserve existing renderer bodies unchanged.

### 5. Projection Contract

Define the exact data returned by the new projection object. Include a realistic
JSON example of the projected render-shape data.

Keep these boundaries explicit:

- projection resolves documents, indexes, defaults, and display-ready values;
- the view partial handles markup and styling;
- the builder preview uses the same projection and partial as runtime;
- malformed configuration produces diagnostics and a safe fallback.

Specify limits on collection size, ordering, duplicate keys, missing documents,
and cyclic references where relevant.

### 6. Structured Builder Experience

Walk through the authoring flow from a schema page:

1. create the view affordance;
2. choose the renderer;
3. configure required bindings;
4. see diagnostics for incomplete settings;
5. preview against a deterministic document;
6. refine settings;
7. use raw JSON to repair unsupported or malformed state;
8. commit the affordance;
9. use it from a document.

Decide which controls appear only for the selected renderer and how changing
renderers handles incompatible existing configuration. Prefer constrained
selects sourced from the current domain/schema inventory over free-form text
where possible.

### 7. Safety and Authorization

Confirm:

- the viewed domain must be visible to the current user;
- resolved documents cannot escape that domain or visibility boundary;
- public/private schema and affordance behavior remains coherent;
- invalid affordances never prevent normal document access;
- deletion and raw repair remain reachable;
- rendering does not mutate source documents.

Call out any authorization behavior that is currently a placeholder rather than
silently relying on it.

### 8. Acceptance Tests

Define tests before implementation:

- validator examples for valid, missing, malformed, and unsupported config;
- projection examples for normal, empty, missing-reference, and ordering cases;
- request coverage for structured settings, preview, commit, and fallback;
- runtime rendering coverage;
- one Playwright flow that creates or opens the affordance, configures it,
  previews it, commits it, and uses it on a document;
- accessibility assertions appropriate to the chosen presentation.

State the exact observable result for each acceptance criterion.

## Required Final Output

Once the decisions converge, produce a design brief with these sections:

1. **Problem and chosen renderer**
2. **Explicit non-goals**
3. **Example source documents**
4. **Renderer JSON contract**
5. **Projection data contract**
6. **Text wireframe**
7. **Structured-builder flow and controls**
8. **Validation, fallback, and authorization rules**
9. **Acceptance-test matrix**
10. **Implementation sequence by file**
11. **Risks and unresolved questions**
12. **Decision log**

The implementation sequence should favor small, independently testable commits:

1. validator and DSL documentation;
2. projection and unit specs;
3. runtime partial and request specs;
4. structured builder and preview;
5. Playwright authoring/use flow;
6. `TASKS.md`, `README.md`, and `AGENT.md` synchronization where appropriate.

End by asking me to approve or revise the brief. Do not edit application files
or begin implementation until I approve it.

---
