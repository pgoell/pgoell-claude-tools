---
name: creating-presentations
description: Use when the user wants an HTML presentation styled from a brand preset, built from a deck.md, a settled storyline, or content they give (notes, figures, bullets), or wants an existing deck reviewed, audited, or polished until done. Includes a presenter view for live sharing. A bare deck ask with nothing to build from goes to designing-presentations first. For hand edits in the browser, see the editing-presentations skill; for editable PowerPoint, see the exporting-presentations-to-pptx skill.
---

# Creating Presentations

Multi-slide HTML decks styled from a brand preset, presented straight from the browser through a bundled deck-stage engine, and reviewed to done through a strict convergence loop. HTML is the working medium: fast to iterate, diffable, and exportable to native PowerPoint later without a redesign pass.

Building and perfecting are one lifecycle. A new deck flows top to bottom through the sections below: resolve the preset, choose a visual direction, compose, then check the render. A bare ask with no `deck.md` and nothing to compose from leaves this skill before the preset step: run `designing-presentations` first, as "Composing the deck" says. The render check runs after every build without asking. A deck that already exists and only needs review enters directly at "Perfecting the deck". The perfecting loop is opt-in: it burns subagent tokens every round, so it starts only when the user asks for it or accepts the offer.

## Dependencies

The decks themselves are dependency-free: self-contained HTML that opens from `file://`. Tools enter only for presenting and perfecting; check for them when those branches start.

- A Chromium-based browser (Edge, Chrome, Arc) presents the deck: `BroadcastChannel` sync and the presenter's "Save to deck" (File System Access API) are Chromium-only. The same binary, headless, screenshots slides for the render check and the review loop: `chrome --headless --screenshot=slide.png --window-size=1920,1080 --hide-scrollbars <url>` (on Windows the preinstalled `msedge.exe` accepts the same flags). Headless Chrome sizes the viewport, so this gives a 1920x1080 image of the whole slide.
- `uv` serves the deck over HTTP for the hard gates (`uv run python -m http.server 8123 --directory <deck-dir>`); webfonts and `BroadcastChannel` behave differently on `file://` origins.
- The default render check and the perfecting loop need subagent dispatch (the Workflow tool, or the Agent tool as fallback) for its judges and verifiers. Cursor has no Workflow tool: it takes the fallback path in `references/review-loop.md` with its `Task` tool. Context isolation is what keeps the loop honest; without subagents, offer the user a single-pass review and say so, rather than simulating the loop inline.

## Resolve the preset first

Before writing any slide, resolve which preset styles the deck:

1. Prompt wins. An explicit preset name ("use the acme-corp preset") or a path to a preset directory settles it, and so does a `preset` key in the `deck.md` header.
2. Otherwise check `.pgoell/presentations/config.md` at the working repo root. Its `## Preset` section selects the active preset by `Name:` (resolved against local presets first, then bundled ones) or `Path:` (any directory that follows the preset contract). When the file names a preset, use it and say so.
3. Otherwise look for local presets in `.pgoell/presentations/presets/*/` at the working repo root. Exactly one: use it and say so. More than one: ask the user which to apply.
4. Otherwise choose among the bundled presets in `presets/` at the plugin root (`../../presets/` relative to this skill's directory) by the deck's use, state the choice and the reason in one line, and name the alternatives. `analytical` for decks read by or presented to decision makers, `keynote` for stage talks in dark rooms (and any `deck_mode: keynote`), `product` for launches and engineering all-hands, `editorial` for data stories and research readouts, `workshop` for training and mixed or low-vision audiences, `technical` for engineering deep dives, architecture reviews, design docs presented live, and incident reviews, and `default` when nothing points elsewhere. When the use is unclear and the user is present, ask. The table in `../../presets/README.md` under "Bundled presets" is the reference.
5. A brand the user names but no preset covers: offer the `extracting-presets` skill to build one from their brand material, and use a bundled preset only after they agree.

Once the preset is resolved, read `references/preset-contents.md`: the eight things a preset contributes (variable files, guidelines, `language.md`, assets, icons, fonts, the slide gallery) and how to consume each one.

## Choose a visual direction

Before composing a new deck, choose its look: propose three or four directions drawn from the subject's industry, materials, and vernacular (background, accent with its job, type pairing, one motif, layout concept), always including the quiet default look; render one sample slide per direction side by side; let the user pick, or in an autonomous run compare two at a time with the order swapped; then lock the winner as `direction.md` and `direction.css` next to the deck. With a client preset active, only the motif and layout concept are open. The full procedure, including the palette-swap test and when to skip, is in `references/visual-direction.md`.

## The canvas

Author every slide on a 1920x1080 canvas (16:9). Layout grammar:

- Outer padding 80 to 120 px. The empty space is part of the brand.
- 12-column grid with 32 px gutters as a soft guide. A preset that declares its own grid as layout tokens in `colors.css` (`--grid-cols`, `--grid-col`, `--grid-gutter`, and zone tokens such as `--title-top` or `--body-top`) wins over this default; its `guidelines.md` documents the grid under `## Layout grammar`.
- One idea per slide. Three ideas means three slides.
- Type from the preset's scale tokens: body 40 px (never under 36), captions, chart labels, and table cells at least 28 px, footer and source line at least 24 px. At most three text sizes per slide, footer aside; a hero number or a workshop time box marked `data-role="hero"` is the one exception. Never shrink text to fit: split the slide, cut words, or move detail to the notes. Hard gate H7 measures this by role, so mark small text with `data-role="caption"`, `"label"`, `"legend"`, `"footer"`, or `"source"` when its class does not say what it is (a section tracker counts as footer when marked `data-role="footer"`); `references/hard-gates.md` lists every allowed value. These floors are starting points from the exporter's arithmetic (0.5 pt per px), not sourced numbers.
- Footer only where the preset needs one: a source line, a brand wordmark, or legal elements its `language.md` requires. Keep it lighter than the content, with no full-width accent rule and no slide counter. Structure slides (title, section divider, quote, closing) carry no footer and use the preset's dark scope, so the audience sees where the deck turns.
- The numbered visual rules (V1 to V13: two families, one accent with a stated job, same color same meaning, left-aligned body, lists of two to four, line length, change signals information, chart rules, a source line on every number) live in `references/deck-standards-default.md`. Read them before composing; the render check and judges cite them.

## Deck contract

Emit decks that honor this structure, so the stage engine, the presenter view, the review probes, and the PPTX exporter consume them without rework:

- Each slide is a `<section>` with a `data-screen-label` attribute carrying a short human-readable slide name (the presenter view displays it and the PPTX export uses it as the slide name). Slides are the direct element children of one `<deck-stage>` element; never place slides outside it.
- Slides are addressed by 1-based index on the URL hash (`#3`).
- Speaker notes live in a JSON island keyed by 1-based slide index. Notes are the presenter's voice, not filler: carry over what a `deck.md` source brief or the user provides, and otherwise leave a slide's entry out; the presenter view handles missing notes gracefully ("No notes for this slide"), while an invented note puts words in the presenter's mouth. When shaping notes you were given, make them complement the slide rather than repeat it. For presented and keynote decks use cues: short phrases, the key numbers, and a transition line to the next slide. For briefing and reading decks, full prose is fine. Size notes at about 130 spoken words a minute of the slide's time.

  ```html
  <script type="application/json" id="speaker-notes">
  { "1": "Open with the value prop. Twenty seconds." }
  </script>
  ```

- All styling flows through CSS custom properties declared in `:root` or in a preset variant scope such as `.dark`. Hardcoded colors in slide markup break preset swapping and the PPTX token lift.

## The stage engine

This skill bundles the deck-stage engine in its `assets/` directory. The deck loads seven scripts: `deck-print.js`, `deck-controls.js`, `deck-thumbs.js`, `deck-edit.js`, `deck-rail.js`, `deck-stage.js`, and `presenter.js`. The presenter window is `presenter.html` with its sidecar files `presenter-view.css` and `presenter-notes.js`. Copy all ten files unmodified next to the deck; they are brand-neutral and carry no preset styling. `deck-stage.js` defines the `<deck-stage>` web component: CSS-transform scaling of the authored canvas to any viewport, keyboard navigation (arrows, Space, Home/End, number keys), a resizable thumbnail rail with drag-to-reorder and skip (each thumbnail is a live clone of its slide, styled by the deck's own CSS), a print stylesheet that lays one slide per page so Print to PDF just works, and slide hiding via `visibility` so iframe and video state survives navigation. Tooling that measures geometry (the review probes, the PPTX exporter) sets the `noscale` attribute on `<deck-stage>` to read authored-canvas pixels.

Wire a deck like this, with the scripts in this order: the five `deck-*` part files must load before `deck-stage.js`, which builds the element from them. A deck from an older engine (one `deck-stage.js`, no part files) keeps working as it is; to update it, copy all ten files and add the five part scripts, since the new `deck-stage.js` alone leaves the deck blank.

```html
<style>deck-stage:not(:defined){visibility:hidden}</style>
<deck-stage>
  <section data-screen-label="01 Title">...</section>
  ...
</deck-stage>
<script src="deck-print.js"></script>
<script src="deck-controls.js"></script>
<script src="deck-thumbs.js"></script>
<script src="deck-edit.js"></script>
<script src="deck-rail.js"></script>
<script src="deck-stage.js"></script>
<script src="presenter.js"></script>
```

## Composing the deck

When a `deck.md` from the `designing-presentations` skill exists, it is the source brief. Its header may carry `deck_mode` (`presented`, `keynote`, `briefing`, or `reading`; a missing header or key means `presented`), `governing_idea`, `sequencing`, `emotional_lever`, `star_moment`, and `preset`; deck mode sets the word budget, the notes format, and the title length (keynote titles are short claims with the full sentence in the notes). Its audience brief seeds the deck brief in the constitution. Its per-slide blocks name each slide's type, headline, visual, and speaker notes. Render the headline as written as the slide's dominant heading (`h1.action` in the gallery); a block's short `title` label, when a layout shows one, sits above it in a smaller size and never takes the dominant position. A visual brief that pins a gallery layout by name settles the layout choice. Without a `deck.md`, when the request carries content, figures, or a storyline, compose directly from it. Without a `deck.md` and with nothing to compose from (a bare ask such as "a deck about our Q3 results"), run the `designing-presentations` skill first: it asks for the material and writes the `deck.md`; then render that.

**Copy.** Write every surface to the active `language.md` (the preset's, or the default preset's). Never add a fact, figure, name, quote, date, or calculation that is not in the source material or the user's input; when a claim needs a number the source lacks, write the claim with what the source does have and tell the user what is missing. After the build, hard gate H8 runs the copy lint in `references/copy-lint.md`; its long word lists stay there and out of the prompt.

**Layouts and visuals.** Before choosing the first layout, read `references/layouts-and-visuals.md`: how to pick each slide's layout from its argument role and proof object (the role-to-gallery table and the `slides/index.tsv` search), what to do when no gallery layout fits, and the rules for builds, image slots (`data-placeholder="image"`), images, icons, and charts.

## Output layout

Multi-file is the shape for a deck that lives in a repo: `index.html`, the deck's own CSS file, the ten engine files, and an `assets/` directory. Single-file is the shape for a deck that travels as one attachment (mail, Teams): inline the deck CSS into the HTML, inline each of the seven deck scripts as its own `<script>` block in the order above, inline SVG as markup, and base64-encode raster images. Either shape opens from `file://` without a server. The presenter view needs `presenter.html`, `presenter-view.css`, and `presenter-notes.js` next to the deck file, so a strictly single file has no presenter mode; when presenter mode matters for a traveling deck, ship the deck with those three files.

## Check the render

After every build, before handing the deck over, run the default render check from `references/review-loop.md`: hard gates H1 to H9 (`references/hard-gates.md` and `references/copy-lint.md`) plus one screenshot pass by one fresh subagent against the constitution's flaw taxonomy (occlusion, font sizing, alignment, spacing, contrast, misplaced decoration, leftover placeholder). Fix what it finds with the smallest change and check again, two fix rounds by default and three at most; then report what passed and what is still open, including any slide that still carries `data-placeholder="image"`. First renders usually have real defects, and a fresh look finds what the builder no longer sees. This check is not the perfecting loop: offer the loop afterwards for decks that must be flawless.

## Presenter mode

When the user is about to present the deck, or asks how, read `references/presenter-mode.md`: the deck and presenter keys, live notes editing and "Save to deck", how the two windows sync, and how to share in Teams, Zoom, or Meet without leaking the notes.

To change a finished deck by hand, or to point at elements instead of describing them, see the `editing-presentations` skill.

## Perfecting the deck

A strict reviewer that does not stop at "looks good". The loop dispatches fresh judge and verifier subagents every round (`Task` calls in Cursor), so it is token intensive; it runs only on the user's go-ahead. A request to review, audit, polish, or perfect the deck is that go-ahead. After building a deck and running the render check, offer the loop instead of starting it: name the cost (several subagents per round, typically a few rounds) and wait for a yes.

Once the loop has its go-ahead, read `references/perfecting.md` before round 1: the three rules that keep the loop convergent, when the loop stops (the hard gates, two dry rounds, and the round cap), the constitution (`deck-standards.md` next to the deck) and its deck brief, the five steps of one round, severity and strict mode, and the `report.md` each round updates. It links `references/review-loop.md` for the judge and verifier prompts.

## Caveats

- Decks that load webfonts or icons from CDNs render differently offline. Every bundled preset vendors its fonts under `assets/fonts/`; copy them with the deck as described above, and vendor any other webfont the same way, otherwise font fallbacks produce false overflow findings.
- Screenshot judges need vision via the Read tool on PNG files; capture screenshots to disk first, then pass paths.
