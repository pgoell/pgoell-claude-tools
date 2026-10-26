# From measured HTML to pptxgenjs

The export writes the same structured deck as the `building-pptx-decks` Build route, with the HTML as the source of geometry. Read `../../building-pptx-decks/references/from-preset.md` first: units, theme slots, fonts, layouts, charts and the traps all apply unchanged. This file adds what is particular to an HTML source.

## Theme and layouts from the deck

- **Tokens**: resolve the deck's own `:root` custom properties (last declaration in document order wins; in decks from `creating-presentations` the preset values are inlined after the deck defaults). Never lift values from the plugin's `presets/` directory alone: the deck may have overridden them. Map them onto the twelve theme slots as `from-preset.md` says and apply them with `pptx_tool.py theme`.
- **Layouts**: group slides by frame. Every slide whose title sits at the same rect, size and color shares a layout; structure slides (title, divider, quote, closing) share the dark ones. Define one `defineSlideMaster()` per group with the title as a named placeholder at the measured rect, the footer and source line on the layout, and the slide background from the section's computed background. Typically four to six layouts cover a deck.
- **Titles fill placeholders**: the slide's dominant heading goes in the `title` placeholder by name. Everything else is composed on the slide.

## Mapping items

Work through each slide's `items` in order and convert with `IN()` and `PT()`:

- **`text`**: a text box at `rect` with `isTextBox: true`, `margin: 0`, `valign: 'top'`, `fontSize: PT(fontPx)`, `bold` when `weight >= 600`, `align` from the item, and `lineSpacing: PT(lineHeightPx)` (exact points; a multiplier inflates every line by about a fifth against the CSS). Letter spacing becomes `charSpacing: PT(letterSpacingPx)`. Color: a scheme color when the hex matches a theme slot, else the hex.
  - Headlines and short labels: one paragraph per entry in `lines`, so LibreOffice and PowerPoint break exactly where the browser did. LibreOffice ignores "do not wrap", so this is the only reliable way to keep a two-line headline at two lines.
  - Body paragraphs: keep them as paragraphs (users edit them) in a box of the measured width plus 2 percent, so a font with slightly wider metrics does not add a line.
  - Lists (`li` items): one text box with `bullet: true` per item, the bullet color from the accent, `paraSpaceAfter` for the gap.
  - Font sizes stay exactly as measured. Never shrink to fit and never set `fit: 'shrink'` or `autoFit`; when a line does not fit at its size, the HTML slide already breaks a floor or overflows: flag the slide to the user instead.
- **`box`**: a shape at `rect`. `RECTANGLE` with no radius, `ROUNDED_RECTANGLE` with `rectRadius: IN(radius)` otherwise (a radius of half the height or more is a pill: `rectRadius: IN(h / 2)`). `fill: { color, transparency }` with transparency `(1 - fillAlpha) * 100`; `line` from `border`, or `{ type: 'none' }`. A CSS `box-shadow` becomes `shadow: { type: 'outer', blur: PT(blur), offset: PT(y), angle: 90, color, opacity }`; drop a shadow so faint it does not show at slide scale. A background image other than a gradient is an `img`.
- **`img`**: `addImage({ path, x, y, w, h })` with the measured rect. A CSS circle crop (`border-radius: 50%`) is `rounding: true`; CSS opacity is `transparency`. SVG sources go in as PNG rasterized at four times the display size (PyMuPDF through `uv`, as in `from-preset.md`, "Icons").
- **`svg`**: a chart when its `data-*` attributes carry the data (`data-chart` names the type: `bar`, `line`, `scatter`, `bubble` and others; `data-labels` and `data-series` hold the values as JSON; `data-highlight` or `data-highlight-series` names the story; `data-unit`, `data-orientation`, axis labels and markers as written): build a native chart with the recipes in `from-preset.md`, the story series or bar in the accent and the rest in `--chart-context`, labels on the marks at the caption size. A waterfall is a stacked column chart with an invisible base series. With no readable data (a hand-drawn diagram, a freeform illustration) it becomes a picture: screenshot the slide at 1920 x 1080 with headless Chrome (`--screenshot=slide.png --window-size=1920,1080 --hide-scrollbars "<url>#N"`) and crop the rect with Pillow. Tell the user which charts ship as pictures.
- **`table`**: `addTable()` at the rect with an explicit `w`, column widths from the cells' measured widths when they differ, header fill and cell text sizes from the markup, no banding unless the HTML has it.

Components the gallery repeats (an editor window with a title bar, a facts strip, a stamp, a layer stack) get one builder function each in the generator, so every instance comes out the same.

## Speaker notes and metadata

The deck's `<script type="application/json" id="speaker-notes">` island holds notes keyed by 1-based slide number: `slide.addNotes(text)` on each slide that has an entry, nothing on the others. Set `pres.title` from the deck's `<title>` and `pres.author`.
