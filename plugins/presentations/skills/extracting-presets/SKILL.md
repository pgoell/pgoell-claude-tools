---
name: extracting-presets
description: Use when the user wants to create or extend a client preset from existing brand material, such as a PowerPoint template, PDF brand guidelines, or example decks worth keeping. Extracts colors, typography, and assets, and rebuilds selected slides as reusable HTML. Triggers on requests like "add <client> as a preset", "extract our corporate design from this pptx", or "rebuild this template in HTML".
---

# Extracting Presets

Turn client brand material into a preset: the pack of CSS variables, assets, and example slides that the `creating-presentations` skill consumes. The point of extraction is reuse. A slide rebuilt once in clean HTML gets adapted into every future deck for that client, so fidelity and self-containment matter more than speed.

The preset contract (directory shape, rules, selection semantics) lives in `../../presets/README.md` at the plugin root. Read it before writing any preset file; this skill describes the workflow, the contract file defines the output.

## Inputs

Ask for whatever exists; more sources make a better preset:

- A PPTX template or example decks. Best source: the theme XML carries the exact color palette and font scheme. A large template or timesaver slide library gets its own recipe in the template slide libraries section below.
- PDF brand guidelines or PDF-exported decks.
- Assets from the official brand portal (wordmarks, imagery). If no official asset is provided, leave a placeholder and record the gap in the manifest.
- An icon or asset library file, often a PPTX from the brand portal's downloads section. It extracts into the preset's `icons/` member; see the icon libraries section below.
- The client or context name in kebab-case; it becomes the preset directory name.

## Dependencies

Three tools cover every step; check for them before starting. Prefer the cross-platform form of each command so the workflow runs unchanged on macOS, Linux, and Windows.

- `uv` carries all Python work ad hoc, nothing is pre-installed: python-pptx for structured PPTX access, pymupdf for PDFs, Pillow and imagehash for icon QA. It also replaces platform-specific shell tools where they are missing (Windows ships neither `unzip` nor `grep`): `uv run python -m zipfile -e deck.pptx workdir` unpacks a PPTX anywhere, and text scans can run through Python or PowerShell's `Select-String` when `grep` is absent.
- A Chromium-based browser screenshots rebuilt slides at the exact canvas size, no automation framework or MCP server needed: `chrome --headless --screenshot=slide.png --window-size=1920,1080 --hide-scrollbars file:///path/to/slide.html`. On Windows the preinstalled Edge binary (`msedge.exe`) accepts the same flags.
- A container engine renders source PPTX decks for side-by-side comparison, using `docker.io/linuxserver/libreoffice`. Probe for whichever runtime the host has (`podman`, `docker`, and `nerdctl` share the same run syntax) and use the first that answers: `for rt in podman docker nerdctl; do command -v "$rt" && break; done`. Then: `podman run --rm -v "$PWD:/data" --entrypoint soffice docker.io/linuxserver/libreoffice --headless --convert-to pdf /data/deck.pptx --outdir /data`, swapping `podman` for the runtime found, and rasterize the PDF with pymupdf at the dpi the step calls for. A `:Z` volume suffix is SELinux labeling, needed on Fedora-family Linux hosts only. This dependency applies only when a source deck exists to render; a PDF-only or portal-only extraction never touches it, and when no runtime exists at all, record the missing side-by-side render as a manifest gap instead of blocking the extraction.

Brand fonts are a soft dependency: fidelity comparisons render on fallback fonts unless the client typeface is installed on the host, which is worth knowing before judging a side-by-side.

## Workflow

Copy this checklist into the response and tick items off as they complete:

```
- [ ] 1. Inventory the source material
- [ ] 2. Extract palette, typography, expression, and copy guidance into colors.css / typography.css / guidelines.md / language.md
- [ ] 3. Choose slides to build (shortlist from decks; a lone color guide means one palette specimen)
- [ ] 4. Build each chosen slide as self-contained HTML
- [ ] 5. Collect assets and note licensing
- [ ] 6. Write manifest.md
- [ ] 7. Verify every slide passes the contract
- [ ] 8. Place under .pgoell/presentations/presets/<name>/ (or contribute it as a bundled preset)
```

### 1. Inventory the source

A PPTX is a zip archive: `unzip -o deck.pptx -d workdir`. Read `ppt/theme/theme1.xml` for the color scheme (`a:clrScheme`) and font scheme (`a:fontScheme`), `ppt/slideLayouts/` and `ppt/slideMasters/` for layout structure (every PPTX carries at least one master, and it is an extraction source in its own right; see the slide masters section below), and `ppt/media/` for embedded assets. Use python-pptx via `uv` when structured access beats raw XML. Render the source slides to images before rebuilding anything: LibreOffice in a container converts a PPTX to PDF reliably (driving desktop PowerPoint by AppleScript stalls on large decks, and LibreOffice may be absent on the host), then pymupdf rasterizes the pages. The rebuild and the step 7 comparison both need this visual reference; the XML alone hides how a slide actually composes. For PDFs, use pymupdf: rasterize pages for visual reference, list embedded fonts, extract images. A portal page printed to PDF carries the canonical page URL and the capture timestamp in the browser's print header and footer; lift the manifest citation from there.

When an example figure is the only source of a color (chart series colors, typically), extract the embedded image and read values from its large flat fills with an exact-color histogram; solid chart areas survive compression intact while small legend swatches and thin strokes bleed. Match the sampled values against the palette already extracted, and record near misses as found instead of snapping them silently: an example figure that predates the current palette is itself a finding for the manifest.

Brand color guides print each value several ways at once, usually hex, RGB, CMYK, and Pantone. Hex is canonical for digital work; keep Pantone and print notes as comments beside the variables. Cross-check the printed hex against the printed RGB, guides carry typos, and record any mismatch in the manifest as found instead of silently correcting it.

### 2. Extract palette, typography, and guidance

Write `colors.css` and, when the font stacks diverge from the defaults, `typography.css`, both as `:root` custom property declarations. Structure `colors.css` in two layers:

- Raw brand variables carry the guide's own names under a short client prefix (`--acme-blue: #0045AD;`) with Pantone or print notes as trailing comments, so every value stays traceable to the source. When the guide restricts a color (limited use, functional only), carry the rule as a comment block beside the variables it governs; future decks inherit the constraint through the file. Encode sanctioned gradients as `linear-gradient` variables the same way.
- Semantic variables (`--bg`, `--fg`, `--accent`, `--fs-h1`) map raw values onto slide intent. Slides read only the semantic names unless a specific brand value is the point (charts, swatches, brand-pinned motifs that must stay one exact color); that is what keeps preset swapping possible.

The semantic mapping is a design decision, not extraction: propose which raw colors become the default look and whether a variant is worth encoding (a dark inverse for title and divider slides is common), then let the user decide. Encode each variant as a class scope after `:root` (`.inverse { --bg: ...; }`) so a slide or region opts in with one class and every `var()` reference flips.

Check accent contrast in both directions before mapping. A brand accent often works as a graphic on white yet fails as text (a bright brand green on white can land around 2.3:1); map a darker ramp step as `--accent-ink` for accent-colored text and keep the bright value in `--accent` for graphics.

Not every rule has a variable to ride on. Brand expression guidance (personality attributes, tone of voice, imagery selection rules) goes into `guidelines.md`, condensed to what steers a slide decision; skip the portal boilerplate. Keep guidance files rule-only: source attributions, capture dates, and divergence notes belong in the manifest (step 6), not in the files every deck build loads, where each provenance sentence is a recurring token cost.

Copy rules from the brand's style guide (terminology, word usage, required legal language) go into `language.md`, written as a positive contract: say what good copy does, then show it with before/after title rewrites in the brand's own voice. Keep the default preset's anti-fabrication rule (never add a fact, figure, name, or arithmetic the source lacks) in every `language.md`. When the brand states no copy rules, write no `language.md`; consumers then fall back to the default preset's.

### 3. Shortlist slides to rebuild

Do not rebuild the whole deck. Propose a shortlist covering the structural slide types (title, divider, agenda, one or two content layouts, closing) plus any slide the user flags as worth keeping: the architecture slide that landed well, the comparison layout that worked. The user picks the final list.

When the source is a color guide with no deck to mine, steps 3 and 4 collapse to a single palette specimen: a real slide layout that shows the palette groups and exercises the semantic mapping in every encoded variant. It validates the mapping in a browser and gives the gallery its first entry; the structural slide set follows once real deck material exists. Record the missing pieces (typography, wordmark, slide set) as manifest gaps.

### 4. Rebuild each slide

One self-contained HTML file per slide in `slides/`, on a 1920x1080 canvas: inline `<style>` scoped to the slide, every color and font read through the preset's variables, no network requests. The only file references a slide may make are relative paths into the preset's own `assets/`; step 5 says when those are the right call. Standalone opening requires the variables to travel with the slide: embed a copy of the preset's variable blocks (`colors.css`, plus `typography.css` when present) at the top of the inline `<style>`, marked with a comment naming the source files, and refresh the copy whenever they change. Fidelity to the source layout beats creative improvement; this is extraction, not redesign. Two rules outrank fidelity. Type meets the floors on the 1920x1080 canvas: body at least 36px (40px is the default), captions and chart labels at least 28px, footer and source line at least 24px, never shrunk to fit. And the slide carries no template chrome: no tracked uppercase eyebrow over the title, no accent-colored period, no italic accent word, no mono micro labels, no 01 / 02 numbering where nothing is a sequence, no middle-dot meta strings. When the source template itself uses small type or one of these marks, rebuild at the floor or without the mark and record the source value as an extraction decision in the manifest. Icons come only from the preset's `icons/` library or official assets, never drawn freehand; with neither, the slide carries no icon. Fidelity extends to imagery: a photo or figure on the source slide already exists in `ppt/media/`, so extract and place that file rather than approximating it with CSS; a gradient stand-in for a photograph reads as an unfinished placeholder, and the user will send it back. Simplify only effects with no extractable asset behind them (decorative gradient washes, WordArt), toward the brand's flat values, and record the deviation in the manifest. Source slides stack imagery, marks, and text, so give layered absolutely positioned elements explicit `z-index` instead of trusting DOM order, which has painted a cover image over the client logo.

### 5. Collect assets

Prefer SVG, it inlines as text. Small rasters (logos, badges) base64-inline. Photographic imagery keeps its source quality: when inlining would force lossy recompression, keep the original file in `assets/` and have the slide reference it by relative path (`../assets/<file>`), noting the choice in the manifest; the slide still opens standalone from the preset directory. Compressing a source photo until it squeezes inline trades away exactly the fidelity the preset exists to keep. Record font licensing in the manifest when the brand typeface is licensed rather than free; the deck skill must know whether it can embed the font or must fall back.

Official logo and wordmark downloads need their own care:

- A portal bundle typically ships parallel digital (RGB) and print (CMYK, Pantone) trees in several formats. Bundle the digital RGB tree only, SVG preferred; the print formats stay portal-only and the manifest says so.
- Mark artwork is immutable. Never recolor it or normalize it to `currentColor` the way an icon library is normalized; marks carry brand-locked colors. Cross-check the mark's fills against the extracted palette: a match corroborates both, a mismatch is a manifest finding.
- Variants that look interchangeable can be distinct artwork. A tagline lockup in standard and large-use cuts differs in proportion for viewing distance, not in resolution, and scaling one never yields the other. Bundle only the variants the preset's surfaces may actually use and record the rest as portal-only.
- Official bundles carry their own artifacts, filename typos for example. Normalize names when copying into `assets/` and record the artifacts as found.
- Mark artwork often bakes its clearspace into the SVG canvas as padding around the visible mark. Measure the visible bounding box before sizing the mark on a slide, and absorb the baked padding with layout offsets rather than cropping the viewBox, so the artwork file stays untouched.

### 6. Write the manifest

`manifest.md` is the preset's single home for provenance: who the preset serves, the sources with their dates, what the preset covers, the extraction decisions (divergences recorded as found, with the resolution, including type lifted to the floors and chrome dropped), and what is missing (no official logo yet, no dark variant, closing slide pending). Add one direction line naming the generic default the preset's look avoids (for example, "deep navy and one warm accent; avoids the off-white, lime, and sans-everything default"), so a reader can tell the brand apart from the stock look. Every other preset file stays rule-only and may point here; provenance written anywhere else costs tokens on every deck build.

Cite sources as durable references a reader can follow: the brand portal URL and page path with the capture date. Never reference provided files by name (a local PDF, a template on someone's disk); they do not ship with the repo, so everything relevant is extracted into the preset and the live portal is the only reference back.

### 7. Verify

Every rebuilt slide opens standalone in a browser, references only variables declared in the preset's variable files, resolves any relative asset references within the preset, and makes no network requests. Check the variable references with a grep pass (`var(--` names against the declarations) rather than by eye, and diff each slide's embedded variable block against `colors.css` and `typography.css`; a drifted copy shows stale values the moment the slide opens standalone. Check type the same way: read computed `font-size` by role in the browser (body at least 36px, captions and labels 28px, footer and source 24px), and grep the slides for the chrome marks named in step 4 (`text-transform: uppercase` with `letter-spacing`, `<em>` or `font-style: italic` inside titles, the middle dot U+00B7). Fix and re-check until every slide in the preset passes; a slide that fails the contract silently breaks preset swapping later.

The contract checks are mechanical; verification is also visual. Screenshot every rebuilt slide at exactly 1920x1080 with a headless browser and compare it side by side against the step 1 source render before presenting anything; slides that passed every grep have shipped with placeholder art and a logo painted over. Treat every visible defect in the screenshot as real and chase it to a cause in the HTML; a defect waved off as a preview artifact comes straight back as a user correction (a clipped wordmark blamed on screenshot resolution was DOM paint order).

### 8. Place the preset

The default home for a new preset is `.pgoell/presentations/presets/<name>/` at the working repo root: it is user-owned, consumed by `creating-presentations` alongside the bundled presets, and requires no plugin change. Only when the user explicitly wants the preset shipped with the plugin does it go into `presets/<name>/` at the plugin root (`../../presets/` relative to this skill's directory); that is a plugin change and needs the plugin version bumped per the marketplace repo's lockstep rules.

## Icon libraries

A PPTX icon library extracts into the preset's `icons/` member (shape and index format in the contract). The workflow differs enough from slide extraction to have its own recipe:

- Vector art hides in two storages, so inventory both before writing any code: embedded SVG media (`asvg:svgBlip` relationship references resolving to `ppt/media/*.svg`, copy the files directly) and native freeform shapes (`a:custGeom` paths that need conversion). A grep count of `svgBlip` versus `custGeom` per slide sizes the work in seconds.
- Before building a custGeom converter, scan the whole file for the drawing features actually used: path command types, preset geometries, line properties, and where fills come from. Icon suites are typically simple (`moveTo`, `lnTo`, `cubicBezTo`, `close`, with circles exported as beziers, so no arc math), fills resolve through the shape's own `solidFill`, then the inherited group fill, then the theme scheme in `theme1.xml`, and paths render with `fill-rule="evenodd"` so ring shapes stay donuts. Scaling the converter to the observed feature set keeps it small.
- Expect generic shape names ("Graphic 4"); searchable metadata must be assembled instead: slide titles become categories, keyword text boxes tag icons by spatial association, and per-icon names are assigned by visual inspection of rendered contact sheets (fan out vision subagents at scale, have them write JSON to disk rather than chat, and validate full id coverage before merging).
- Normalize an icon to `currentColor` only when it is provably monochrome, and check `stroke` as well as `fill`; keep genuinely multicolor icons as found and record their fixed colors in the index.
- QA gates before the library lands: XML-parse every output (official files carry corruption, such as stray trailing bytes), rasterize thumbnails and eyeball sample sheets, flag bounding-box aspect-ratio outliers (they expose mis-grouped shapes and sliver artifacts), and dedupe visually identical icons with a perceptual hash, keeping the merged duplicates' tags as aliases.
- Record in the manifest: that names are extraction-assigned search aids rather than official nomenclature, any source-file artifacts found, and any referenced sets that stay portal-only.

## Slide masters

The slide master is the skeleton every slide inherits, and any PPTX source has one at `ppt/slideMasters/slideMaster1.xml`, even a plain example deck. Check for it on every PPTX extraction, not only template libraries; it settles values that individual slides never state because they inherit them.

- **Walk the inheritance chain before trusting any slide value.** A slide resolves through its layout (slide rels into `ppt/slideLayouts/`), the layout through its master (layout rels), the master through the theme (master rels), and the master's `clrMap` remaps scheme slots on the way (bg1/tx1 landing on lt1/dk1 or their inverses). A color or size read off a slide without the chain comes out wrong exactly when the deck relies on inheritance most.
- **Type scale and bullet hierarchy.** The master's `p:txStyles` (title, body, other styles) carries per-level `sz`, weights, `buChar`/`buFont`, and indents; a 13.333in deck converts to the 1920px canvas at 2px per pt. Land the results as the preset's `--fs-*` variables and bullet rules, and reconcile against portal statements with divergences recorded as found. Templates often set body at 12 to 16pt (24 to 32px), below the floors in step 4: lift those variables to the floor and record the template value and the lift as an extraction decision.
- **Skeleton geometry.** Placeholder frames on the master and its layouts (title, body, and the `ftr`, `sldNum`, `dt` footer trio) carry positions and sizes in EMU (6350 EMU per px at 1920 wide). That geometry is the brand's canvas padding, title block, and footer band: encode it in `guidelines.md` as the sanctioned skeleton and reuse it when rebuilding slides, so the gallery sits where the template sits.
- **Backgrounds and artwork.** Master and layout `p:bg` fills define the default surfaces and often confirm whether a dark variant is sanctioned (a dark master or divider layout corroborates an `.inverse` scope). Artwork riding on the master or its layouts (resolve picture rels into `ppt/media/`) is official by definition and frequently absent from portal downloads; extract it into `assets/` per the step 5 rules.
- **Defaults are a finding, not a brand.** A master whose values are stock Office defaults (Calibri stacks, the untouched default scale) is evidence the deck never customized it; record that as found and prefer portal or template values instead of encoding Office defaults as brand. Template libraries can also carry several masters, each grouping its own layouts: inventory `ppt/slideMasters/` fully and note which layouts hang off which master before assuming one skeleton.

## Template slide libraries

A brand's working PowerPoint template or "timesaver" library (often hundreds of slides) is a source class of its own: it settles questions the portal pages leave open, because it encodes what the brand actually ships. Lessons from extracting one:

- Inventory by table of contents, not by rendering. A slide-per-line listing of layout name plus first text frame (python-pptx) maps a 300-slide deck in seconds, and the deck's own section dividers segment it. Note that the first text frame is often a subtitle placeholder, so read placeholder types and layout names rather than trusting "the title". Render low-dpi numbered contact sheets (about 40dpi, 24-up) for the shortlist conversation, then re-render only the chosen slides at working resolution as build reference.
- The slide masters recipe above carries the type scale, bullet hierarchy, and footer geometry; in a template library, each layout's placeholder `lstStyle` additionally overrides the master per level, so read both. A template may state outright that its sizes are user-tested recommendations, which both settles a pending scale and licenses adjusting it.
- The theme's accent order can encode the sanctioned chart series cycle. Verify against the actual chart parts, counting series-fill sequences across every `c:ser` in `ppt/charts/`, rather than trusting the theme or a single chart; the most frequent full-length order is the cycle.
- Layout names are brand vocabulary: the catalogue of cover, divider, and content-family layouts belongs in `guidelines.md` as the sanctioned skeleton. But names can be stale against the theme (a layout named for a renamed color, filling with a different one); check each named layout's actual `bg` fill and record divergences as found.
- Layout rels reveal official artwork the portal downloads withhold: `grep` the layout for its pictures, resolve the rels to `ppt/media/`, and official raster marks (tagline lockups, campaign badges) fall out. Raster artwork base64-inlines into slides; measure the alpha-channel bounding box first and record the baked clearspace so slides can place the file at the layout's own geometry.
- Shape colors hide in three places: run properties, the shape's `spPr` solidFill, and the `p:style` fillRef. Parsers must allow attributes on the elements (`<p:spPr bwMode=...>` breaks a naive literal match). When parsing frustrates, render the slide and read the pixels; the two together beat either alone. Bottom-anchored text (`anchor="b"`) becomes CSS absolute positioning from the bottom, so text grows upward as the template does.
- Templates carry their own typos, even on their brand-recap slides (palette values that contradict the portal); the recap slides are corroboration, not new ground, so the portal stays canonical and the typos are recorded as found. Yellow authoring-note boxes are template aids, never design; exclude them from rebuilds but mine them for compliance statements. Expect tooling artifacts such as zero-size think-cell OLE placeholders. Dummy-data inconsistencies (a "3" among "3.0" labels) are normalized in the rebuild, not manifest findings.
- Scope the rebuild to the structural slide set plus the layouts the user picks, and record the rest of the library as a catalogue of sanctioned forms in `guidelines.md`; the preset stays a curated gallery while the catalogue tells future decks what shapes exist to reach for.

## Extending an existing preset

New slide material enters the workflow at step 3, into the existing preset directory. When a deck built with the `creating-presentations` skill produced a new slide worth keeping, this skill folds it back into the preset.

A new guidance source with no slides to mine (another portal page, an updated brand guide) re-enters at step 2 instead: merge its rules into the existing `colors.css`, `typography.css`, and `guidelines.md`, then update the manifest's sources, coverage, and gaps. Reconcile every new rule against what earlier pages already settled, and record cross-page divergences in the manifest as found, with a resolution when one page is more specific. Two follow-ons are easy to miss: a variable change must be synced into every existing slide's embedded variable block (step 4's sync rule applies to extensions too), and extending a bundled preset is still a plugin change that needs the version bump from step 8 (local `.pgoell` presets need no repo change).

## Cross-references

- The `creating-presentations` skill consumes the presets this skill produces.
- The `exporting-presentations-to-pptx` skill converts finished HTML decks back to PowerPoint; its EMU and point conversions are also useful when measuring a source PPTX during extraction.
