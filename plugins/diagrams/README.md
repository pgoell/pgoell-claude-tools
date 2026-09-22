# Diagrams

Draw architecture, workflow, sequence, data-flow, and lifecycle diagrams as one self-contained HTML file: inline SVG, light and dark modes, and SVG, PNG, and clipboard export. No build step, no dependencies, no network requests.

## Skills

- `/diagrams:creating-diagrams`: Draw a diagram from a description, pasted Mermaid, or a repository scan. Plans layout on a grid, renders both modes in headless Chromium, and reviews the screenshots against a fixed checklist before handing over.

## Themes

Every color comes from a theme variable, so one block swap restyles a diagram. The plugin ships `classic` (slate and Tailwind-style accents, in both modes). Contract: [`themes/README.md`](themes/README.md).

To match a corporate brand, derive a theme from material you already have:

- a presentations preset (built from a PowerPoint template by `/presentations:extracting-presets`), or
- a `.pptx` or `.potx` file directly, from its theme colors and fonts.

The skill writes the derived theme to `.pgoell/diagrams/themes/<name>/` in your repo and records it in `.pgoell/diagrams/config.md`, so later diagrams use it without asking. Derived themes never leave your repo.

**Setup:** optional. Install a Chromium-based browser (Chrome, Chromium, or Edge) for the visual review step; without one, the skill says the review was skipped.

## Credits

This plugin combines two MIT-licensed projects:

- [Cocoon-AI/architecture-diagram-generator](https://github.com/Cocoon-AI/architecture-diagram-generator) (Cocoon AI): the dark palette, page layout, opaque-mask technique, and spacing rules.
- [tt-a1i/archify](https://github.com/tt-a1i/archify) (tt-a1i): the five diagram types, the semantic class and CSS-variable theme system, light mode, and the layout checks and repair order.

No upstream file is vendored verbatim. `NOTICE` maps each file to what it took from which project. Original work is MIT licensed.
