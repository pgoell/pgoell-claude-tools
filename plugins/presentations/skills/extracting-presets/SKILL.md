---
name: extracting-presets
description: Use when the user wants to create or extend a client preset from existing brand material, such as a PowerPoint template, PDF brand guidelines, or example decks worth keeping. Extracts colors, typography, and assets, and rebuilds selected slides as reusable HTML. Triggers on requests like "add <client> as a preset", "extract our corporate design from this pptx", or "rebuild this template in HTML".
---

# Extracting Presets

Turn client brand material into a preset: the pack of CSS variables, assets, and example slides that the `creating-presentations` skill consumes. The point of extraction is reuse. A slide rebuilt once in clean HTML gets adapted into every future deck for that client, so fidelity and self-containment matter more than speed.

The preset contract (directory shape, rules, selection semantics) lives in `../../presets/README.md` at the plugin root. Read it before writing any preset file; this skill describes the workflow, the contract file defines the output.

## Inputs

Ask for whatever exists; more sources make a better preset:

- A PPTX template or example decks. Best source: the theme XML carries the exact color palette and font scheme. A large template or timesaver slide library gets its own recipe in [references/template-libraries.md](references/template-libraries.md).
- PDF brand guidelines or PDF-exported decks.
- Assets from the official brand portal (wordmarks, imagery). If no official asset is provided, leave a placeholder and record the gap in the manifest.
- An icon or asset library file, often a PPTX from the brand portal's downloads section. It extracts into the preset's `icons/` member; see [references/icon-libraries.md](references/icon-libraries.md).
- The client or context name in kebab-case; it becomes the preset directory name.

## Dependencies

Three tools cover every step; check for them before starting. Prefer the cross-platform form of each command so the workflow runs unchanged on macOS, Linux, and Windows.

The exact commands for each tool (`uv` for Python work, a headless Chromium browser for slide screenshots, a container engine for LibreOffice renders of source decks) are in [references/tools.md](references/tools.md).

Brand fonts are a soft dependency: fidelity comparisons render on fallback fonts unless the client typeface is installed on the host, which is worth knowing before judging a side-by-side.

## Workflow

Copy this checklist into the response and tick items off as they complete:

```
- [ ] 1. Inventory the source material
- [ ] 2. Extract palette, typography, expression, and copy guidance into colors.css / typography.css / guidelines.md / language.md
- [ ] 3. Choose slides to build (shortlist from decks; a lone color guide means one palette specimen)
- [ ] 4. Build each chosen slide as HTML that links the preset's variable files
- [ ] 5. Collect assets and note licensing
- [ ] 6. Write manifest.md
- [ ] 7. Verify every slide passes the contract
- [ ] 8. Place under .pgoell/presentations/presets/<name>/ (or contribute it as a bundled preset)
```

### 1. Inventory the source

A PPTX is a zip archive: `unzip -o deck.pptx -d workdir`. Read `ppt/theme/theme1.xml` for the color scheme (`a:clrScheme`) and font scheme (`a:fontScheme`), `ppt/slideLayouts/` and `ppt/slideMasters/` for layout structure (every PPTX carries at least one master, and it is an extraction source in its own right; see [references/slide-masters.md](references/slide-masters.md)), and `ppt/media/` for embedded assets. Use python-pptx via `uv` when structured access beats raw XML. Render the source slides to images before rebuilding anything: LibreOffice in a container converts a PPTX to PDF reliably (driving desktop PowerPoint by AppleScript stalls on large decks, and LibreOffice may be absent on the host), then pymupdf rasterizes the pages. The rebuild and the step 7 comparison both need this visual reference; the XML alone hides how a slide actually composes. The render commands are in [references/tools.md](references/tools.md). For PDFs, use pymupdf: rasterize pages for visual reference, list embedded fonts, extract images. A portal page printed to PDF carries the canonical page URL and the capture timestamp in the browser's print header and footer; lift the manifest citation from there.

A large template or timesaver library is inventoried by table of contents first; follow [references/template-libraries.md](references/template-libraries.md).

When a color comes from an example figure or a printed color guide, read it per [references/colors.md](references/colors.md).

### 2. Extract palette, typography, and guidance

For a PPTX source, read the type scale, bullet hierarchy, and skeleton geometry off the slide master per [references/slide-masters.md](references/slide-masters.md).

Write `colors.css` and, when the font stacks diverge from the defaults, `typography.css`, both as `:root` custom property declarations. Structure `colors.css` in two layers:

- Raw brand variables carry the guide's own names under a short client prefix (`--acme-blue: #0045AD;`) with Pantone or print notes as trailing comments, so every value stays traceable to the source. When the guide restricts a color (limited use, functional only), carry the rule as a comment block beside the variables it governs; future decks inherit the constraint through the file. Encode sanctioned gradients as `linear-gradient` variables the same way.
- Semantic variables (`--bg`, `--fg`, `--accent`, `--fs-h1`) map raw values onto slide intent. Slides read only the semantic names unless a specific brand value is the point (charts, swatches, brand-pinned motifs that must stay one exact color); that is what keeps preset swapping possible.

The semantic mapping is a design decision, not extraction: propose which raw colors become the default look and whether a variant is worth encoding (a dark inverse for title and divider slides is common), then let the user decide. Encode each variant as a class scope after `:root` (`.inverse { --bg: ...; }`) so a slide or region opts in with one class and every `var()` reference flips.

Before mapping, check accent contrast (text at 4.5:1) and map the chart token group, both per [references/colors.md](references/colors.md).

Not every rule has a variable to ride on. Brand expression guidance (personality attributes, tone of voice, imagery selection rules) goes into `guidelines.md`, condensed to what steers a slide decision; skip the portal boilerplate. Record the layout grammar there too, under `## Layout grammar`: the grid (columns, gutter, margins, and the zones where tracker, title, body, and footer sit), declared as layout tokens in `colors.css` (`--grid-cols`, `--grid-col`, `--grid-gutter`, zone tokens such as `--title-top`), plus the compositions the brand's slides repeat. Consumers build any layout the gallery lacks from that grammar. Keep guidance files rule-only: source attributions, capture dates, and divergence notes belong in the manifest (step 6), not in the files every deck build loads, where each provenance sentence is a recurring token cost.

Copy rules from the brand's style guide (terminology, word usage, required legal language) go into `language.md`, written as a positive contract: say what good copy does, then show it with before/after title rewrites in the brand's own voice. Keep the default preset's anti-fabrication rule (never add a fact, figure, name, or arithmetic the source lacks) in every `language.md`. When the brand states no copy rules, write no `language.md`; consumers then fall back to the default preset's.

### 3. Shortlist slides to rebuild

Do not rebuild the whole deck. Propose a shortlist covering the structural slide types (title, divider, agenda, one or two content layouts, closing) plus any slide the user flags as worth keeping: the architecture slide that landed well, the comparison layout that worked. The user picks the final list.

From a template library, shortlist with low-dpi contact sheets and record the unbuilt layouts as a catalogue in `guidelines.md`, per [references/template-libraries.md](references/template-libraries.md).

When the source is a color guide with no deck to mine, steps 3 and 4 collapse to a single palette specimen: a real slide layout that shows the palette groups and exercises the semantic mapping in every encoded variant. It validates the mapping in a browser and gives the gallery its first entry; the structural slide set follows once real deck material exists. Record the missing pieces (typography, wordmark, slide set) as manifest gaps.

### 4. Rebuild each slide

One HTML file per slide in `slides/`, on a 1920x1080 canvas: `<link rel="stylesheet" href="../colors.css">`, plus `<link rel="stylesheet" href="../typography.css">` when present, before an inline `<style>` that holds only the slide's own rules, every color and font read through the preset's variables, no network requests. The only file references a slide may make are those two links and relative paths into the preset's own `assets/`; step 5 says when those are the right call. The slide opens standalone from the preset directory. Fidelity to the source layout beats creative improvement; this is extraction, not redesign. Two rules outrank fidelity. Type meets the floors on the 1920x1080 canvas: body at least 36px (40px is the default), captions and chart labels at least 28px, footer and source line at least 24px, never shrunk to fit. And the slide carries no template chrome: no tracked uppercase eyebrow over the title, no accent-colored period, no italic accent word, no mono micro labels, no 01 / 02 numbering where nothing is a sequence, no middle-dot meta strings. When the source template itself uses small type or one of these marks, rebuild at the floor or without the mark and record the source value as an extraction decision in the manifest. Icons come only from the preset's `icons/` library or official assets, never drawn freehand; with neither, the slide carries no icon. Fidelity extends to imagery: a photo or figure on the source slide already exists in `ppt/media/`, so extract and place that file rather than approximating it with CSS; a gradient stand-in for a photograph reads as an unfinished placeholder, and the user will send it back. Simplify only effects with no extractable asset behind them (decorative gradient washes, WordArt), toward the brand's flat values, and record the deviation in the manifest. Source slides stack imagery, marks, and text, so give layered absolutely positioned elements explicit `z-index` instead of trusting DOM order, which has painted a cover image over the client logo.

Tag each rebuilt slide: add one row to the preset's `slides/index.tsv` (create it with its header row if missing), with values from the closed vocabulary in `../../presets/TAGS.md` and a summary of at most 15 words.

### 5. Collect assets

Prefer SVG, it inlines as text. Small rasters (logos, badges) base64-inline. Photographic imagery keeps its source quality: when inlining would force lossy recompression, keep the original file in `assets/` and have the slide reference it by relative path (`../assets/<file>`), noting the choice in the manifest; the slide still opens standalone from the preset directory. Compressing a source photo until it squeezes inline trades away exactly the fidelity the preset exists to keep. Record font licensing in the manifest when the brand typeface is licensed rather than free; the deck skill must know whether it can embed the font or must fall back. An open-licensed brand face is vendored as unmodified woff2 files with its license under `assets/fonts/<family>/`, declared by `@font-face` in `typography.css`, with provenance (source, version, license, Reserved Font Name) in the manifest; never subset a family that carries a Reserved Font Name.

Official logo and wordmark downloads need their own care; follow [references/brand-marks.md](references/brand-marks.md). An icon library file extracts into `icons/` per [references/icon-libraries.md](references/icon-libraries.md).

### 6. Write the manifest

`manifest.md` is the preset's single home for provenance: who the preset serves, the sources with their dates, what the preset covers, the extraction decisions (divergences recorded as found, with the resolution, including type lifted to the floors and chrome dropped), and what is missing (no official logo yet, no dark variant, closing slide pending). Add one direction line naming the generic default the preset's look avoids (for example, "deep navy and one warm accent; avoids the off-white, lime, and sans-everything default"), so a reader can tell the brand apart from the stock look. Every other preset file stays rule-only and may point here; provenance written anywhere else costs tokens on every deck build.

Cite sources as durable references a reader can follow: the brand portal URL and page path with the capture date. Never reference provided files by name (a local PDF, a template on someone's disk); they do not ship with the repo, so everything relevant is extracted into the preset and the live portal is the only reference back.

### 7. Verify

Every rebuilt slide opens standalone in a browser, references only variables declared in the preset's variable files, resolves any relative asset references within the preset, and makes no network requests. Check the variable references with a grep pass (`var(--` names against the declarations) rather than by eye, and check that each slide links `../colors.css` and, when present, `../typography.css`. Check type the same way: read computed `font-size` by role in the browser (body at least 36px, captions and labels 28px, footer and source 24px), and grep the slides for the chrome marks named in step 4 (`text-transform: uppercase` with `letter-spacing`, `<em>` or `font-style: italic` inside titles, the middle dot U+00B7). Fix and re-check until every slide in the preset passes; a slide that fails the contract silently breaks preset swapping later.

The contract checks are mechanical; verification is also visual. Screenshot every rebuilt slide at exactly 1920x1080 with a headless browser (command in [references/tools.md](references/tools.md)) and compare it side by side against the step 1 source render before presenting anything; slides that passed every grep have shipped with placeholder art and a logo painted over. Treat every visible defect in the screenshot as real and chase it to a cause in the HTML; a defect waved off as a preview artifact comes straight back as a user correction (a clipped wordmark blamed on screenshot resolution was DOM paint order).

### 8. Place the preset

The default home for a new preset is `.pgoell/presentations/presets/<name>/` at the working repo root: it is user-owned, consumed by `creating-presentations` alongside the bundled presets, and requires no plugin change. Only when the user explicitly wants the preset shipped with the plugin does it go into `presets/<name>/` at the plugin root (`../../presets/` relative to this skill's directory); that is a plugin change and needs the plugin version bumped per the marketplace repo's lockstep rules.

## Extending an existing preset

New slide material enters the workflow at step 3, into the existing preset directory. When a deck built with the `creating-presentations` skill produced a new slide worth keeping, this skill folds it back into the preset.

A new guidance source with no slides to mine (another portal page, an updated brand guide) re-enters at step 2 instead: merge its rules into the existing `colors.css`, `typography.css`, and `guidelines.md`, then update the manifest's sources, coverage, and gaps. Reconcile every new rule against what earlier pages already settled, and record cross-page divergences in the manifest as found, with a resolution when one page is more specific. One follow-on is easy to miss: extending a bundled preset is still a plugin change that needs the version bump from step 8 (local `.pgoell` presets need no repo change).

## Cross-references

- The `creating-presentations` skill consumes the presets this skill produces.
- The `exporting-presentations-to-pptx` skill converts finished HTML decks back to PowerPoint; its EMU and point conversions are also useful when measuring a source PPTX during extraction.
