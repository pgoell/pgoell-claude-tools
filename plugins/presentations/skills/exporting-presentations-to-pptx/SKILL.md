---
name: exporting-presentations-to-pptx
description: Use when the user wants to export or convert an HTML presentation into a native, editable PowerPoint file (.pptx) with real text boxes, autoshapes, embedded images, and speaker notes. Triggers on requests like "make a PowerPoint version of this deck", "export the slides to pptx", or "the client needs the editable file". For building the HTML deck itself, see the creating-presentations skill.
---

# Exporting Presentations to PPTX

Convert an HTML deck into a fully native, editable PowerPoint: real text boxes and autoshapes, exact design-token colors, embedded images, and speaker notes carried over. Not screenshots on slides. Consultants edit the result in PowerPoint, so every element must be a real PowerPoint object.

## Inputs to gather

1. The deck HTML. Every `<section>` is one slide; `data-screen-label` names it. The `<script type="application/json" id="speaker-notes">` island holds notes keyed by 1-based slide number.
2. The design tokens (`:root` CSS custom properties) and per-slide layout rules. Resolve each token to its effective value in the deck HTML: the last `:root` declaration in document order wins (in decks from the `creating-presentations` skill, preset values are inlined after the deck defaults and win). Never lift token values from the plugin's `presets/` directory alone; that recolors the deck wrongly.
3. Image assets the deck references (wordmarks, photos, illustrations).

Output path: for a single-file deck, write next to the HTML with the same basename and a `.pptx` extension. For a multi-file deck, write `<deck-dir-basename>.pptx` into the deck directory root, never `index.pptx`.

## Dependencies

Two tools cover every step; check for them before starting.

- `uv` carries all Python work, nothing is pre-installed:

  ```bash
  uv venv /tmp/pptx-venv
  uv pip install --python /tmp/pptx-venv/bin/python python-pptx pillow pymupdf
  ```

  PyMuPDF covers both PDF rasterization for the verify loop and SVG rasterization for asset prep, so cairosvg stays out of the default install. Add it only when PyMuPDF mis-renders an SVG (see self-healing below); it needs libcairo, checked with `brew list cairo` on macOS or `ldconfig -p | grep libcairo` on Linux.

- A container engine runs LibreOffice for render verification when the host has no `soffice` binary. Probe for whichever runtime the host has (`podman`, `docker`, and `nerdctl` share the same run syntax) and use the first that answers: `for rt in podman docker nerdctl; do command -v "$rt" && break; done`, then `podman pull docker.io/linuxserver/libreoffice:latest`, swapping `podman` for the runtime found.

## Author in deck pixel space

Author everything in the HTML deck's own pixel space and convert once:

- Slide: 12192000 x 6858000 EMU (standard 16:9).
- 1 stage px = 6350 EMU (12192000 / 1920).
- 1 stage px = 0.5 pt for font sizes (a 56 px CSS headline is 28 pt; 40 px body is 20 pt, a 28 px caption or chart label 14 pt, a 24 px footer or source line 12 pt).

These constants assume the 1920x1080 canvas that the `creating-presentations` skill authors on. Verify the stage size in the deck CSS before converting; for a different stage width W, use 12192000 / W EMU per px and 960 / W pt per px.

Every value then lifts straight from the CSS (paddings, font sizes, gaps) with no separate design pass.

Keep every font size exactly as the CSS states it. Never shrink text to fit a box, in code or through PowerPoint autofit: when text does not fit at its CSS size, the HTML slide already breaks the type floors or overflows, so flag the slide to the user (the fix is to split or cut it in the deck) instead of exporting smaller type.

## Prepare assets

python-pptx cannot place SVGs, crop pictures to a circle, or set picture transparency. Pre-render PNGs first:

- SVGs: rasterize with PyMuPDF at the target display width times four for crispness: `fitz.open("logo.svg")`, then `page.get_pixmap(matrix=fitz.Matrix(k, k), alpha=True)` with `k = 4 * target_width / page.rect.width`. Eyeball the result against the browser render; if PyMuPDF garbles it, fall back to cairosvg (see self-healing below).
- Circle crops (headshots): center-crop square with PIL, apply a supersampled antialiased circle mask, save RGBA. One PNG at 4x the largest display size serves both large and small uses.
- CSS opacity on images: bake it into the PNG alpha channel before placing.

## Write the generator

Write a fresh Python script for this deck; per-slide code is deck-specific, so never template slide content from a previous conversion. What transfers is the helper layer and the gotchas, both in `references/python-pptx-recipes.md`. Read that file before writing any code: each gotcha originally cost a render-fix cycle to find.

Build with a thin helper layer (`tb()` rich text boxes, `rect()` shapes, builders for components the deck repeats, `est_lines()` for stacked layouts). Proof objects (charts, tables, 2x2 matrices, process flows, full-bleed images with an overlay) have their own recipe in the same file: charts become native, editable PowerPoint charts when the data can be read from the markup, and a picture only when it cannot. Carry the speaker notes from the HTML JSON island into each slide's notes frame, and set the document title and author core properties.

Run the generator with the venv interpreter: `/tmp/pptx-venv/bin/python build_deck.py`.

## Render-verify loop

Never deliver an unrendered export. Convert to PDF, rasterize, and look at every slide:

```bash
podman run --rm -v <workdir>:/data --entrypoint soffice docker.io/linuxserver/libreoffice:latest \
  --headless --convert-to pdf --outdir /data /data/<deck>.pptx
```

Rasterize each PDF page with PyMuPDF (`page.get_pixmap(dpi=96).save("slide-NN.png")`) and read every PNG. Fix and re-render; expect 2 to 4 cycles. The first render finds the big breaks (shadows, wraps, overflow); later cycles find rhythm issues. Treat renders as geometry and color checks, not glyph checks: the verification renderer substitutes fonts, so glyph differences are expected and harmless.

Also check type sizes in the XML, not by eye: `unzip -p <deck>.pptx 'ppt/slides/*.xml' | grep -o 'sz="[0-9]*"' | sort | uniq -c`. Any run under `sz="1200"` (12 pt, the 24 px footer floor) is a bug in the generator or a floor the HTML already broke; trace it before delivering.

## Adversarial verification (optional)

Recommended for high-stakes client deliverables; skippable for quick conversions. Fan out one reviewer subagent per slide, as parallel Agent calls in one message. Each reviewer gets the HTML path plus the slide's `data-screen-label`, the design-token list, and the slide's render PNG path, and reports findings as severity plus description.

Two prompt details that matter:

- Enumerate the known intentional deviations (typo fixes, renderer font substitution, conservative-gap whitespace), or the panel drowns you in false positives.
- Treat color claims about thin glyphs skeptically; pixel-sampling antialiased strokes produces false "wrong color" findings. Verify any surprising color claim against the pptx XML: `unzip` the file and grep the run's `srgbClr`.

## Content fidelity

Reproduce the deck verbatim, with two exceptions: fix obvious typos and report each fix to the user, and apply the preset's language rules (its `language.md`, or the default preset's `language.md` when it has none) to any text you must genuinely rewrite. Slide numbering, footer labels, and which slides carry no footer come from the HTML, not from convention.

## Self-healing

- PyMuPDF garbles an SVG (it supports a subset of SVG; CSS-styled artwork can break): install cairosvg and rasterize with `cairosvg.svg2png(..., output_width=...)`, or ask the user for PNG versions of the assets.
- No podman and no local `soffice`: still deliver the `.pptx`, and state plainly that render verification was skipped and the layout is unverified. Never skip verification silently.
- PyMuPDF prints "No common ancestor in structure tree" warnings while rasterizing: harmless, ignore them.

## Cross-references

- The `creating-presentations` skill builds the HTML decks this skill consumes.
- The `extracting-presets` skill works the other direction: from an existing PowerPoint toward reusable HTML.
