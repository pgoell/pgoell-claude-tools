# Diagrams

Architecture, workflow, sequence, data-flow, and lifecycle diagrams as one self-contained HTML file, rendered by a bundled engine that validates layout geometry before it hands anything over. The viewer has light and dark modes, pan and zoom, search, focus, guided views, a presentation mode, and PNG, JPEG, WebP, SVG, and WebM export. Artifacts make no network requests.

## Skills

- `/diagrams:creating-diagrams`: Draw a diagram from a description, pasted Mermaid, or a repository scan. The agent writes a small typed JSON specification; the engine lays it out, routes edges, runs nine geometry checks (overlaps, edges through nodes, crossings, shared corridors, label clearance, and more), delivers the HTML with SHA-256 receipts, and checks it in headless Chrome. Repository diagrams can cite source lines that the engine verifies against the checked-out commit. Without Node, the skill falls back to a hand-drawn SVG template.

## Engine

`skills/creating-diagrams/engine/` is a vendored copy of [archify](https://github.com/tt-a1i/archify) 2.17.0-dev.1: plain Node ES modules, no dependencies, no install step. It needs Node 18 or later. Beyond rendering it can diff two architecture versions (`compare`), migrate old workflow files, and look up brand logos. The update notifier and three brand marks with restrictive licenses were removed; `NOTICE` lists every change.

## Themes

Every color comes from a theme. The plugin ships `classic`. Contract: [`themes/README.md`](themes/README.md).

To match a corporate brand, derive a theme from material you already have:

- a presentations preset (built from a PowerPoint template by `/presentations:extracting-presets`), or
- a `.pptx` or `.potx` file directly, from its theme colors and fonts.

The skill writes the derived theme to `.pgoell/diagrams/themes/<name>/` in your repo and records it in `.pgoell/diagrams/config.md`; the engine applies it with `--theme`. Derived themes never leave your repo.

**Setup:** Node 18 or later for the engine (without it, the skill uses the hand-drawn fallback). A Chromium-based browser (Chrome, Chromium, or Edge) enables the browser check and visual review.

## Credits

- [tt-a1i/archify](https://github.com/tt-a1i/archify) (tt-a1i, MIT): the vendored engine, viewer, schemas, and authoring workflow.
- [Cocoon-AI/architecture-diagram-generator](https://github.com/Cocoon-AI/architecture-diagram-generator) (Cocoon AI, MIT): archify's upstream; its palette, page layout, and spacing rules also shape the hand-drawn fallback.
- JetBrains Mono (SIL Open Font License 1.1), embedded in the viewer template.
- Brand marks from Simple Icons 16.28.0; see `skills/creating-diagrams/engine/THIRD_PARTY_NOTICES.md`.

`NOTICE` maps every vendored file, lists every modification, and records the dash substitution rules.
