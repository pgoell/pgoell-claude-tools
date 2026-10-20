---
name: exporting-decks-to-pptx
description: Deprecated, superseded by presentations:exporting-presentations-to-pptx. Formerly used to export an HTML deck into a native, editable PowerPoint file (.pptx). Prefer the presentations plugin for all new exports.
---

# Exporting Decks to PPTX

> **Deprecated.** Superseded by `presentations:exporting-presentations-to-pptx`. This copy is archived and no longer maintained.

Convert a workbench deck-stage HTML presentation into a fully native, editable PowerPoint file: real text boxes and autoshapes, exact design-token colors, embedded images, and speaker notes carried over. Not screenshots on slides.

## When to use this skill

Use when the user asks for a PowerPoint or pptx version of an existing HTML deck: "make a PowerPoint version of presentations/<deck>/", "export this deck to pptx", "I need an editable pptx of these slides".

Do not use this skill to build a new presentation; that is `deprecated:crafting-presentations`. This skill consumes that skill's output.

## Inputs to gather

1. The deck HTML. Auto-detect the layout:
   - Single-file deck: a directory containing one `.html` with styles, runtime, and notes inlined.
   - Multi-file deck: a `slides/` layout with `slides/index.html` plus `slides/slides.css` and the runtime JS.
     Every `<section>` is one slide; `data-screen-label` names it. A `<script type="application/json" id="speaker-notes">` block holds presenter notes keyed by 1-based slide number.
2. The design tokens (`:root` CSS variables) and per-slide-type layout rules. Read the shared CSS first, then the deck's own inline `<style>` block in the HTML head. Decks override tokens locally, so the inline overrides win; lifting a token from the shared CSS alone will recolor the deck wrongly.
3. Image assets the deck references (headshots, brand SVGs, logos).

Output path: for a single-file deck, write next to the HTML with the same basename and a `.pptx` extension. For a multi-file deck, write into the deck directory root as `<deck-dir-basename>.pptx`, never `index.pptx`.

## Environment setup

No sudo needed. Use `uv`, never direct `python` or `pip`:

```bash
uv venv /tmp/pptx-venv
uv pip install --python /tmp/pptx-venv/bin/python python-pptx pillow cairosvg pymupdf
docker pull linuxserver/libreoffice:latest   # render verification
```

cairosvg needs libcairo; check with `ldconfig -p | grep libcairo`. LibreOffice runs from the Docker image when the host has no `soffice` binary.

## Step 1: Prepare assets

python-pptx cannot place SVGs or crop pictures to a circle, so pre-render PNGs with PIL and cairosvg:

- Headshots: center-crop square, resize to 4x the largest display size, apply a 4x supersampled antialiased circle mask, save RGBA. One PNG serves both large and small uses.
- Watermarks and wordmarks: `cairosvg.svg2png(..., output_width=...)`, then multiply the alpha channel to bake the CSS opacity in, because python-pptx cannot set picture transparency.

## Step 2: Author in deck pixel space

Author everything in the HTML deck's own pixel space and convert once:

- Slide: 12192000 x 6858000 EMU (standard 16:9).
- 1 stage px = 6350 EMU (12192000 / 1920).
- 1 stage px = 0.5 pt for font sizes (a 56px CSS headline is 28pt).

Every value then lifts straight from the CSS (paddings, font sizes, gaps) with no separate design pass. The conversion helpers live in `references/python-pptx-recipes.md`.

## Step 3: Write the generator

Write a fresh python script for this deck; never template slide content from a previous conversion, because per-slide code is deck-specific. What transfers is the helper layer and the gotchas, both in `references/python-pptx-recipes.md`. Read that file before writing any code: each gotcha originally cost a render-fix cycle to find.

Build with a thin helper layer (`tb()` rich text boxes, `rect()` shapes, builders for repeated components, `est_lines()` for stacked layouts). Carry the speaker notes from the HTML JSON into each slide's notes frame and set the document title and author core properties.

Run the generator with the venv interpreter: `/tmp/pptx-venv/bin/python build_deck.py`.

## Step 4: Render-verify loop

```bash
docker run --rm -v <workdir>:/data --entrypoint soffice linuxserver/libreoffice:latest \
  --headless --convert-to pdf --outdir /data /data/<deck>.pptx
```

Rasterize each PDF page with PyMuPDF (`page.get_pixmap(dpi=96).save("slide-NN.png")`) and read every PNG. Fix and re-render; expect 2 to 4 cycles. The first render finds the big breaks (shadows, wraps, overflow); later cycles find rhythm issues. Treat renders as geometry and color checks, not glyph checks: the verification renderer substitutes fonts.

## Step 5: Adversarial verification (optional)

Recommended for high-stakes decks; skippable for quick conversions. Fan out one reviewer subagent per slide. Claude Code: parallel `Agent` calls in one message. Codex: its subagent equivalent, or review the slides sequentially. Each reviewer gets the HTML path plus the slide's `data-screen-label`, the design-token list, and the slide's render PNG path, and reports findings as severity plus description.

Two prompt details that matter:

- Enumerate the known intentional deviations (typo fixes, renderer font substitution, conservative-gap whitespace), or the panel drowns you in false positives.
- Treat color claims about thin glyphs skeptically; pixel-sampling antialiased strokes produces false "wrong color" findings. Verify any surprising color claim against the pptx XML: `unzip` the file and grep the run's `srgbClr`.

## Content fidelity rules

Reproduce the deck verbatim, with two exceptions: fix obvious typos and report each fix to the user, and apply the user's writing rules to any text you must genuinely rewrite. Slide numbering, footer labels, and which slides carry no footer come from the HTML, not from convention.

## Self-Healing

- cairosvg import or render fails: check libcairo with `ldconfig -p | grep libcairo`. If absent, rasterize the SVG another way (PyMuPDF renders SVG) or ask the user for PNG versions of the assets.
- No Docker: check for a local `soffice` binary and run it with the same flags. If neither exists, still deliver the `.pptx`, and state plainly that render verification was skipped and the layout is unverified. Never skip verification silently.
- PyMuPDF prints "No common ancestor in structure tree" warnings while rasterizing: harmless, ignore them.
- Fonts look different in the verification render: expected substitution (the deck fonts are rarely installed in the LibreOffice image). Verify geometry and color, not glyphs.

## Cross-references

- `deprecated:crafting-presentations` builds the deck-stage HTML decks this skill consumes.
- `deprecated:crafting-html` covers one-off single-file HTML artifacts, including its simpler `09-slide-deck.html` deck.
