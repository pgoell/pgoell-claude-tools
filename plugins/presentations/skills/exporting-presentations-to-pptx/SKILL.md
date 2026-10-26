---
name: exporting-presentations-to-pptx
description: Use when the user wants an existing HTML presentation converted into a native, editable PowerPoint file (.pptx) with a theme, layouts, real text boxes, native charts and speaker notes. Triggers on requests like "make a PowerPoint version of this deck", "export the slides to pptx", or "the client needs the editable file". For a new deck as PowerPoint, see building-pptx-decks; for building the HTML deck itself, see creating-presentations.
---

# Exporting Presentations to PPTX

Convert an HTML deck from `creating-presentations` into a native, structured PowerPoint: the deck's tokens in the Office theme, its slide frames as layouts with named placeholders, every text a real text box, charts as native charts, speaker notes carried over. Not screenshots on slides, and not loose boxes: consultants edit the result in PowerPoint, restyle it from the Design tab, and add slides that match.

A new deck that should end up in PowerPoint is built directly with `building-pptx-decks`; this skill is for a deck that already exists as HTML.

## Inputs

1. The deck HTML. Every `<section>` inside `<deck-stage>` is one slide; `data-screen-label` names it. The `<script type="application/json" id="speaker-notes">` island holds notes keyed by 1-based slide number.
2. The deck's design tokens: its `:root` custom properties, resolved as `references/html-to-pptx.md` says.
3. The image assets the deck references.

Output path: for a single-file deck, next to the HTML with the same base name and `.pptx`. For a multi-file deck, `<deck-dir-basename>.pptx` in the deck directory, never `index.pptx`.

## Dependencies

Paths to scripts below are relative to this skill's directory; run them by absolute path from the deck's directory.

- A Chromium-based browser for measuring and for picture fallbacks (Chrome, Chromium, Edge, or `chrome-headless-shell`).
- Node and `pptxgenjs`: `node -e "require('pptxgenjs')"`; when it fails, `npm install --prefix /tmp/pptx-node pptxgenjs` and run with `NODE_PATH=/tmp/pptx-node/node_modules`.
- Python 3 for the shared scripts in `../building-pptx-decks/assets/` (`pptx_tool.py`, `pptx_check.py`), standard library only. `uv` for PyMuPDF and Pillow when SVGs or crops need rasterizing.
- LibreOffice, local or in a container, for the render check (commands in `../building-pptx-decks/SKILL.md`, "Dependencies").

## Step 1: Measure the deck

Run the geometry probe from this skill's `assets/measure-probe.js` against the deck, as [references/measuring-html.md](references/measuring-html.md) describes, and save the result as `geom.json`. It records every text block with its real line breaks, every box, image, chart and table, in canvas pixels. Nothing in the export estimates text height from CSS.

## Step 2: Write the generator

Read `../building-pptx-decks/references/from-preset.md` (units, theme slots, fonts, layouts, charts, and the traps that corrupt files), then [references/html-to-pptx.md](references/html-to-pptx.md) (deriving layouts from the deck, mapping each measured item, charts from `data-*` attributes, picture fallbacks, notes).

Write a fresh `build_pptx.js` for this deck that reads `geom.json` and the notes island. Per-slide code is deck-specific: never reuse slide content from a previous export. Run it, then write the theme:

```bash
NODE_PATH=/tmp/pptx-node/node_modules node build_pptx.js
python3 ../building-pptx-decks/assets/pptx_tool.py theme deck.pptx theme.json
```

Fonts follow `from-preset.md`, "Fonts": the deck's webfonts are not installed in Office, so use the preset's declared PowerPoint fonts, the client font the recipients have, or the stand-in pair for the bundled preset.

## Step 3: Check

Never deliver an unchecked export. Run, fix the generator, and run again:

1. `python3 ../building-pptx-decks/assets/pptx_check.py deck.pptx`: fix every error; it also lists the text sizes in use. Any run under 12 pt is a generator bug or a floor the HTML already broke: trace it.
2. `python3 ../building-pptx-decks/assets/pptx_tool.py text deck.pptx` against the HTML: every slide present, text verbatim, notes carried.
3. Render with LibreOffice to PDF, rasterize every page, and compare each against a screenshot of the same HTML slide at 1920 x 1080. Expect two to four rounds: the first finds the big breaks (wrap, overflow, missing shapes), later ones find rhythm (gaps, alignment). Glyph shapes differ where fonts are substituted; geometry and color must match.

Without LibreOffice or a container engine, deliver the `.pptx` and state plainly that the layout went unchecked. Never skip the check silently.

## Adversarial review (optional)

For a high-stakes client file, offer one reviewer subagent per slide, dispatched in parallel. Each gets the HTML slide screenshot, the PPTX render of the same slide, the token list, and the list of intended differences (typo fixes, font substitution, the stand-in fonts), and reports findings by severity. Check any surprising color claim against the XML (`unzip -p deck.pptx ppt/slides/slideN.xml | grep srgbClr`): sampling thin antialiased glyphs gives false color findings.

## Content fidelity

Reproduce the deck verbatim, with two exceptions: fix obvious typos and report each fix, and apply the preset's `language.md` (or the default preset's) to any text you must genuinely rewrite. Slide numbering, footer labels, and which slides carry no footer come from the HTML.

## Self-Healing

- The probe returns nothing: the dump finished before fonts loaded; raise `--virtual-time-budget`, or serve the deck over HTTP and measure from there.
- An SVG rasterizes wrongly in PyMuPDF (CSS-styled artwork): take the picture from a headless Chrome screenshot of the slide, cropped with Pillow.
- `pptx_check.py` errors on a chart: the trap list in `from-preset.md` names the option; fix it in the generator and rebuild.

## Cross-references

- `creating-presentations` builds the HTML decks this skill consumes.
- `building-pptx-decks` builds new decks as PowerPoint directly, and owns the shared scripts and the structured-deck reference.
- `extracting-presets` works the other way: from an existing PowerPoint toward a reusable preset.
