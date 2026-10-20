---
type: Explanation
title: HTML producers, presets and themes
description: Why HTML output is a skill mode, how single-file producers, multi-file decks and exporters differ, and how presets and diagram themes carry a brand.
tags: [html, presets, themes, presentations, diagrams, contributors]
status: stable
---

# HTML producers, presets and themes

Several skills write HTML. They come in three shapes (single-file producers, multi-file producers, and exporters that consume another skill's artifact) and take their look from their own template or from one of two layers (presentations presets, diagram themes). [HTML producers, presets and themes](/reference/conventions/html-producers-presets-and-themes.md) states the rules; this page keeps the reasons and the history.

## HTML artifact output is a first-class skill mode

`research:running-research` ships an `## Output Format` section plus a `references/research-report-template.html`, and can write markdown or HTML. Its template declares its own CSS variables in its `:root` block, and the report keeps them.

Until 2026-10 the `workbench` plugin held five more such producers (`writing-spec`, `writing-plans`, `brainstorming`, `systematic-debugging`, and `crafting-html` for every standalone HTML artifact no other skill owned) and a theming layer, `crafting-design-systems`: CSS variables, components and images that every producer inlined when a design system was set by prompt or in `.workbench/config.md`. `research:running-research` reached that layer through the installed workbench plugin. When workbench retired into the archive (see [The deprecated archive](/explanation/the-deprecated-archive.md)), the layer went with it, and research dropped its design-system section. Brand looks now come only from presentations presets and the diagram themes derived from them.

## Multi-file HTML producers are a distinct shape

`presentations:creating-presentations` writes a multi-file deck (deck HTML, deck CSS, the deck-stage runtime JS, a presenter sidecar) instead of one inline file. It has no `## Output Format` section (the format is always HTML) and takes its look from presets. A future multi-file producer copies this shape: ship the runtime as bundled `assets/` and document the theming source in the producer's own plugin.

## Artifact exporters are consumers, not producers

`presentations:exporting-presentations-to-pptx` was the first skill whose input is another skill's finished artifact (a `creating-presentations` deck) and whose output is not HTML (`.pptx`). Exporters skip the producer scaffolding: no `## Output Format` section. An exporter reads design tokens from the artifact itself (the deck's shared CSS, then its inline `<style>` overrides, which win). Output paths live in the exporter's own SKILL.md. Producer and exporter point at each other in one sentence each, and the exporter's frontmatter description names the producer, so "build a deck" and "export this deck" never route to the same skill. A future exporter (spec to docx, report to PDF) copies this consumer shape.

## The presentations plugin themes through presets and parameterizes through `.pgoell/presentations/`

The `presentations` plugin owns the whole deck life cycle: `designing-presentations` writes `deck.md`, `creating-presentations` renders and perfects, `editing-presentations` serves a local editor in which the user selects and changes slide elements by hand, `exporting-presentations-to-pptx` exports, and `extracting-presets` builds presets.

Styling flows through presets: packs of `colors.css` (including a shared chart token group, `--chart-highlight`, `--chart-context`, `--chart-grid`, `--chart-1` onward), optional `typography.css`, `guidelines.md` and `language.md`, `assets/` (with vendored, unmodified open fonts and their licenses under `assets/fonts/<family>/`), `icons/`, and example `slides/` that link the variable files. The contract is `plugins/presentations/presets/README.md`.

Presets have two homes. Bundled ones sit under the plugin's `presets/`; adding or changing one is a version-bumped plugin change. There are seven: `default`, a fully de-branded neutral pack with the full 19-layout gallery, and six voice presets from the 2026-09 design systems report (`analytical`, `keynote`, `product`, `editorial`, `workshop`, `technical`). Each voice preset has an eleven-slide gallery built to its own layout grammar, declared as grid tokens in `colors.css` and a `## Layout grammar` section in `guidelines.md`, which a consumer follows to build any layout the gallery lacks. User-local presets sit under `.pgoell/presentations/presets/<name>/` at the consuming repo's root; `extracting-presets` creates them there by default, and they never ship.

Resolution order: an explicit prompt choice; then `.pgoell/presentations/config.md` `## Preset` (`Name:` looks local first, then bundled; `Path:` takes any directory that follows the contract); then the single local preset (with several, ask); then the bundled preset that fits the deck's use per the table in the contract, stated with its reason (`default` when nothing points elsewhere).

The deck-stage engine ships as skill `assets/`, brand-neutral, and is copied unmodified next to each deck. It is split into classic scripts, one module each, because a deck opens from `file://`, where ES modules and `fetch` of sibling files are blocked: `deck-print.js`, `deck-controls.js`, `deck-thumbs.js`, `deck-edit.js` and `deck-rail.js` each leave one global, and `deck-stage.js`, which loads after them, builds the `<deck-stage>` element from those parts. `presenter.js` adds presenter mode to the deck; the presenter window is `presenter.html` with `presenter-view.css` and `presenter-notes.js`. Invariants to check by hand when editing a preset: example slides link the preset's variable files and make no network requests; every text tier holds 4.5:1 contrast on every surface in both scopes; and the dash rule covers `presets/`.

## The diagrams plugin themes through its own theme contract, derived from presentations presets

`diagrams:creating-diagrams` writes HTML but, like the presentations plugin, has no `## Output Format` section (HTML only). Colors flow only through a `theme.css` of two `[data-theme]` blocks (contract in `plugins/diagrams/themes/README.md`), bundled under the plugin's `themes/` (now `classic`) or user-local under `.pgoell/diagrams/themes/<name>/`. Selection order: the prompt, then `.pgoell/diagrams/config.md` `## Theme`, then an offer to derive one from a configured presentations preset, then `classic`.

Brand themes are derived, not hand-built. The skill maps a presentations preset's semantic tokens (or a PPTX `theme1.xml` color and font scheme) onto the seven semantic diagram strokes, so one `extracting-presets` run brands both decks and diagrams.

Two consumers read a theme. The vendored archify engine reads it through its `--theme` flag; the bridge is `engine/renderers/shared/brand-theme.mjs`, a local addition that computes fills and viewer-only tokens and injects one style block that outranks archify's four built-in looks. The hand-drawn fallback template reads it too: its `THEME:START`/`THEME:END` block is a synced copy of `themes/classic/theme.css`, so edit both together.

The engine is a verbatim port of archify at `1bb61c6`, with local changes listed in `plugins/diagrams/NOTICE`. Re-porting a newer upstream means reapplying those changes, the brand-mark removals, and the dash substitution, then running the upstream tests against the result.

## Producer/renderer skill pairs maintain different taxonomies at different abstraction levels

When one skill designs an artifact's content and another renders it, neither forces its taxonomy on the other. The producer lists argument roles (what each unit contributes to the message); the renderer lists layout templates (how each unit sits on screen). The producer ships a recommended mapping table as a non-binding hand-off; the renderer picks its own template from each unit's brief.

The first pair is `presentations:designing-presentations` (content-side slide types, catalog in `plugins/presentations/skills/designing-presentations/references/slide-type-catalog.md`) and `presentations:creating-presentations` (a layout table keyed to the default preset's gallery file names, such as `ContentSlide`, `ChartInsightSlide`, `MatrixSlide`). The producer carries the distinction note near the `deck.md` hand-off, because that is where the artifact is named; the renderer never treats the producer's list as a constraint, so it need not repeat it. The hand-off artifact (`deck.md`) is a brief, not a render config: `slide_type` is a hint. A future pair keeps the two levels apart. Argument role and visual layout are different abstractions, and one shared list would leak rendering concerns into the producer or argument concerns into the renderer.
