---
name: creating-diagrams
description: Use when the user wants an architecture, workflow, sequence, data-flow, or lifecycle (state) diagram as a polished standalone HTML file with inline SVG, light and dark modes, and SVG/PNG export. Takes a plain-language description, pasted Mermaid, or a repository to scan. Themeable, including themes derived from a presentations preset or a PowerPoint template so diagrams match a corporate brand.
---

# Creating Diagrams

Draw one clear diagram as a self-contained HTML file: an inline SVG built from semantic classes, colored only through theme variables, with a light/dark toggle and SVG, PNG, and clipboard export. No build step, no dependencies, no network requests; the file opens anywhere.

## Inputs

- **A description** in plain language. Ask one question only if the main path is unclear; otherwise draw.
- **Pasted Mermaid** (flowchart, sequenceDiagram, stateDiagram). Treat it as a list of facts and re-author it with this skill's layout rules. Do not transliterate Mermaid's layout or styling.
- **A repository.** Read entry points, service definitions, infra code (`docker-compose.yml`, Terraform, Kubernetes manifests, CI config), and the main call paths before drawing. Draw only what the code shows; mark anything inferred with `v-dashed` and say so in the legend. Cite source paths in the summary cards and the commit SHA in the footer (`git rev-parse --short HEAD`).

## Workflow

Copy this checklist into the response and tick items off:

```
- [ ] 1. Pick the diagram type and the main path
- [ ] 2. Resolve the theme
- [ ] 3. Plan the grid
- [ ] 4. Write the HTML from the template
- [ ] 5. Render both modes and review
- [ ] 6. Deliver
```

### 1. Pick the type and the main path

Read `references/diagram-types.md`. Choose `architecture`, `workflow`, `sequence`, `dataflow`, or `lifecycle` from the question the reader asks. Name the one main path the diagram exists to explain, in one sentence; it becomes the SVG `<desc>`. Past 12 primary nodes (15 messages for sequence), split into an overview plus detail diagrams and say so.

### 2. Resolve the theme

Read `../../themes/README.md` for the contract and selection order: prompt choice, then `.pgoell/diagrams/config.md`, then an offer to derive from a configured presentations preset, then `classic`. Bundled themes live in `../../themes/<name>/theme.css`; local ones in `.pgoell/diagrams/themes/<name>/theme.css` at the working repo root.

When the user wants brand colors (a client, a corporate identity, "match our PowerPoint"), read `references/theming.md` and derive a theme from their presentations preset or PPTX file first. Derive once, save it locally, reuse it for every later diagram. After deriving, render a scratch copy of the template's sample with the new theme in both modes and look at it before drawing the real diagram.

### 3. Plan the grid

Read `references/layout-and-review.md`. Write the grid table (columns, rows, node per cell) in your working notes and compute every coordinate from it. Hand-placed coordinates without a grid are the main source of overlaps.

### 4. Write the HTML

Copy `references/template.html` to the output path. Then:

1. Replace the `THEME:START` to `THEME:END` block with the resolved `theme.css`, verbatim.
2. Set `<title>`, `<h1>`, the subtitle, the SVG `<title>` and `<desc>`.
3. Replace the SVG body, keeping `<defs>` (grid pattern and the four arrow markers) and the grid rect. Draw in this order: boundaries, edges, edge labels, nodes (mask rect first), legend.
4. Set the `viewBox` from the grid table.
5. Write 0 to 4 summary cards. Each card answers one question the diagram raises (what each boundary owns, where the data lives, which files implement what). Delete the section when no card earns its place.
6. Set the footer to the source: "From `repo@abc1234`", a document name, or the date.

Rules that hold in every diagram:

- Semantic classes only. No `fill`, `stroke`, or `style` color literals anywhere, including the page CSS. The grid rect's `fill="url(#grid)"` is a pattern reference, not a color, and stays.
- Every edge ends in the marker matching its class (`a-async` uses `url(#arrow-async)`).
- No `<foreignObject>`, no external images, no web fonts, no scripts beyond the template's.
- Text stays at the template sizes or larger. Nothing below 8px.

Output path: the path the user gives; otherwise `diagrams/<slug>.html` at the working repo root, where `<slug>` is the kebab-case title.

### 5. Render and review

Screenshot both modes with headless Chromium (`references/layout-and-review.md`, section 6), open the screenshots, and run the checklist there. Follow its repair order, one change per round. If two rounds in a row fix nothing, stop and report the failing checks honestly. Never claim the review passed without having looked at both screenshots.

When no browser is available, say that the visual review was skipped, and walk the checklist against the grid table instead.

### 6. Deliver

Report, briefly: the file path, the diagram type, the theme used (and whether it was derived this session), the review result per mode, and anything drawn from inference rather than source. Mention that the page's toolbar exports SVG and PNG; the exported SVG has every style inlined, so it drops into slides and docs without this page's CSS.

## Related skills

- `presentations:creating-presentations` builds decks; paste an exported SVG into a slide, or use a diagram theme derived from the same preset so the two match.
- `presentations:extracting-presets` turns a PPTX template or brand guide into the preset this skill derives diagram themes from.
- `workbench:crafting-html` covers standalone HTML artifacts that are not diagrams.

## Self-Healing

- **Screenshot looks cut off at the bottom**: the window is shorter than the page, or the Chrome build paints a viewport about 90px shorter than `--window-size`. Raise the height well past the page.
- **Colors ignore the theme**: a `style` attribute on an SVG element overrides its class. Remove the `style` and rely on the class.
- **Arrowhead is gray on a colored line**: the edge points at `#arrow-default`. Match the marker to the edge class.
- **Lines show through a node**: the node's `c-mask` rect is missing or comes after the styled rect.
- **Node fills look flat or black**: the browser lacks `color-mix()` (versions before 2023). Set explicit `--<type>-fill` values in the theme.
- **Copy button says "Use PNG"**: the Clipboard API needs a secure context; `file://` pages often lack one. Use the PNG button.
- **Exported PNG misses the brand font**: the export uses installed fonts only. Install the face or accept the fallback.
