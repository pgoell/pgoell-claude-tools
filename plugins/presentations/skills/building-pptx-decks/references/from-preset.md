# Build route: a structured deck from a preset

Write one Node script per deck (`build_deck.js` next to the output) with `pptxgenjs`. The deck it writes is structured: a theme carrying the preset's colors and fonts, one layout per slide frame with named placeholders, sections, and slides that fill placeholders by name. Content specific to a slide (a chart, a stat, a process) is composed on top of its layout.

## Units

Presets author on a 1920x1080 canvas. Use the wide layout, 13.333 x 7.5 in, so one canvas pixel is 1/144 in and half a point:

```js
const pptxgen = require('pptxgenjs');
const IN = (px) => px / 144;   // canvas px to inches (positions, sizes)
const PT = (px) => px / 2;     // canvas px to points (font sizes)
const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE';   // set before the first slide; the default is 10 in wide
```

Every value then lifts straight from the preset's tokens: `--fs-h1: 60px` is 30 pt, a 120 px padding is 0.833 in.

## The theme

Read the preset's `colors.css` (the last `:root` declaration of a name wins; resolve `var()` references) and fill the twelve Office theme slots:

| Slot                   | Preset token                                                    | Used for                          |
| ---------------------- | --------------------------------------------------------------- | --------------------------------- |
| `dk1`                  | `--fg`                                                          | text on light slides              |
| `lt1`                  | `--bg`                                                          | light slide background            |
| `dk2`                  | `--bg-inverse`                                                  | structure slides (title, divider) |
| `lt2`                  | `--bg-subtle`                                                   | panels, table header fill         |
| `accent1`              | `--chart-highlight` (resolved, usually `--accent`)              | the one accent, the story series  |
| `accent2` to `accent6` | `--chart-2` to `--chart-6` (repeat from `--chart-1` when fewer) | categorical chart series          |
| `hlink`                | `--accent-ink` when declared, else `--accent`                   | links                             |
| `folHlink`             | `--fg-muted`                                                    | visited links                     |

Write the slots, the fonts and the preset name to `theme.json` and apply them after `writeFile()`: `pptxgenjs` writes Office's stock theme and has no option for theme colors.

```bash
python3 <skill>/assets/pptx_tool.py theme deck.pptx theme.json
```

In the script, use scheme colors wherever an option takes them, so a later theme change in PowerPoint recolors the deck: `const C = pres.SchemeColor;` gives `C.text1` (dk1), `C.text2` (dk2), `C.background1` (lt1), `C.background2` (lt2), `C.accent1` to `C.accent6`. Tokens with no slot (`--fg-muted`, `--fg-subtle`, `--chart-context`, `--border`, the inverse text tiers) go in as hex read from `colors.css`. Chart colors, gridlines and shadows take hex only.

## Fonts

Recipients open the file with the fonts installed on their machine; `pptxgenjs` cannot embed fonts, and the bundled presets' webfonts are not installed in Office. Choose in this order:

1. The preset declares `--pptx-font-head`, `--pptx-font-body` (and optionally `--pptx-font-mono`) in `typography.css` or `colors.css`: use those.
2. A client preset whose brand font the recipients have installed (the manifest says so, or the user confirms): use the brand font.
3. Otherwise the stand-in for the bundled preset:

| Preset                          | Head    | Body    | Mono        |
| ------------------------------- | ------- | ------- | ----------- |
| `default`, `keynote`, `product` | Arial   | Arial   | Courier New |
| `technical`                     | Arial   | Arial   | Courier New |
| `analytical`, `editorial`       | Cambria | Calibri | Courier New |
| `workshop`                      | Cambria | Arial   | Courier New |

These render at true width in LibreOffice and ship with Office, so the render check judges fit correctly. Set `pres.theme = { headFontFace, bodyFontFace }` and the same pair in `theme.json`; name no font on placeholders (titles take the head font, body text the body font). Chart text is the exception: pass `'+mn-lt'` (theme body font) to every chart `*FontFace` option, or it falls back to Arial.

## Layouts from the layout grammar

`defineSlideMaster()` creates a slide layout (all layouts share one master you cannot change), so call them layouts when talking to the user. Take the geometry from the preset's grid tokens (`--grid-*`, zone tokens such as `--title-top`, `--body-top`, `--body-bottom`) and its `guidelines.md` "Layout grammar". When a preset declares no zones, use: side padding 120 px, title zone 80 to 260 px, body zone 300 to 960 px, footer band 1000 to 1040 px.

Define these layouts, light ones on `--bg`, structure ones on the dark scope (`--bg-inverse` or the preset's `.inverse` or `.dark` scope):

| Layout           | Surface | Placeholders (name, type)                                    | Serves `slide_type`                      |
| ---------------- | ------- | ------------------------------------------------------------ | ---------------------------------------- |
| `Title`          | dark    | `title` (title), `subtitle` (body)                           | Title                                    |
| `Section`        | dark    | `title` (title), `summary` (body)                            | SectionDivider                           |
| `Title only`     | light   | `title` (title), `source` (body, footer band)                | Decision, Evidence, Transformation       |
| `Title and body` | light   | `title` (title), `body` (body), `source` (body, footer band) | Agenda, Appendix with text, exec summary |
| `Closing`        | dark    | `title` (title), `body` (body)                               | Closing                                  |

Rules for every placeholder:

- Give `x`, `y`, `w`, `h`, `fontSize`, `color`, `bold`, `valign: 'top'` and `margin: 0` from the tokens. Always set `align: 'left'` on titles: a title placeholder inherits centered alignment otherwise.
- Size the title box for two lines at the preset's `--fs-h1` and its line height; action titles run to two lines at most.
- Footer content (the source line, a wordmark from the preset's `assets/`, `slideNumber`) lives on the layout, never on a slide. Structure slides carry no footer.
- Names in `masterName` and `placeholder` fail silently when misspelt (a blank layout, a stray box at the top left). Keep them in constants.

## Filling slides

```js
pres.addSection({ title: 'The evidence' });          // from SectionDivider slides, or one per pyramid reason
const s = pres.addSlide({ masterName: L.TITLE_ONLY, sectionTitle: 'The evidence' });
s.addText(block.headline, { placeholder: 'title' }); // the headline verbatim, as the dominant heading
s.addText(block.sources, { placeholder: 'source' });
s.addNotes(block.speaker_notes);                     // plain text, once per slide
```

Fill placeholders by name with no position, size or color, so the layout decides. A block's short `title` label, when present, goes in a small text box above the title zone at the caption size in `--fg-muted`; it never takes the dominant position. Sections without a `sectionTitle` on every slide land in a stray "Default" section.

## Proof objects

The `visual` brief names the proof object. Pick the gallery layout for it the way `creating-presentations` does: the mapping in `../../designing-presentations/references/slide-type-catalog.md` ("Rendering hand-off"), the preset's `slides/index.tsv`, or a layout the brief pins by name. Open that gallery slide (`presets/<name>/slides/<Layout>.html`) and take its composition from it: where the chart sits, the column split, the size of the hero number. To read exact boxes instead of estimating from CSS, measure the gallery slide in headless Chrome with the probe in `../../exporting-presentations-to-pptx/references/measuring-html.md` and convert with `IN()` and `PT()`.

Compose on the `Title only` layout, in scheme colors, and give each shape an `objectName` so the user can find it in the selection pane:

- **Charts** stay native and editable: `addChart()` for bar, column, line, pie, doughnut, scatter and combos (an array of `{ type, data, options }`). Highlight mode: one series in the accent, everything else in `--chart-context`. For a single series, `chartColors` with one hex per bar colors bars individually: context gray everywhere except the story bar. Label values on the marks (`showValue: true`, `dataLabelPosition`), hide the legend for one series, quiet the axes (`valAxisHidden` or a light `valGridLine`, `catGridLine: { style: 'none' }`), and set every label size to the caption floor (`PT(28)`, 14 pt) with `'+mn-lt'` fonts. Data comes from the material, never from memory.
- **Waterfall** (a total built up or broken down): a stacked column chart with an invisible base series under the visible step series.
- **Table**: `addTable()` with the header row in `lt2`, cell text at the caption floor or larger, no banding unless the gallery slide has it, and an explicit `w`. A table that needs auto-paging is too long for one slide: split it.
- **One number**: a text box at `--fs-hero` in the accent or `text1`, with its label below at the caption floor.
- **Process, 2x2, comparison, timeline**: shapes plus text boxes (`ROUNDED_RECTANGLE` with `rectRadius` for cards, `line` shapes with an arrow end for flows), each box editable. Gaps from the grid gutter.
- **Image**: `addImage()` with `sizing: { type: 'contain' }` or `'cover'`; photos at source quality. An empty slot is a gray shape labeled "Image: <what goes here>", reported at hand-over.
- **Diagram**: simple flows as native shapes; anything denser as a picture exported from `diagrams:creating-diagrams` with a theme derived from the same preset. Report pictures at hand-over, since they are not editable.
- **Icons** come only from the preset's `icons/` library: rasterize the SVG to PNG at four times its display size (`uv run --with pymupdf python3`, `fitz.open(svg)`, `get_pixmap(matrix=fitz.Matrix(k, k), alpha=True)`) and place it with `addImage`. No icon library, no icons.

## Traps

Each of these writes a file PowerPoint repairs, refuses, or renders wrongly; `pptx_check.py` catches the ones marked (checked).

- Hex colors take six digits and no `#` (`'1D4ED8'`) (checked). Translucency is `transparency` (0 to 100) on fills and images, `opacity` on shadows.
- `pptxgenjs` converts option objects in place on first use: build a fresh options object for every `add*` call, never share one.
- Shadow `offset` and `blur` are never negative (checked); aim a shadow with `angle`.
- Letter spacing is `charSpacing` (in points); a `letterSpacing` key is ignored.
- Lists: `bullet: true` per item (never a typed bullet character), `breakLine: true` on every item but the last, `paraSpaceAfter` for the gap (not `lineSpacing`).
- Every free text box gets `isTextBox: true` and, when it must align with a shape edge, `margin: 0`.
- `rectRadius` works on `ROUNDED_RECTANGLE` only.
- No gradient fills: use a gradient image as the background.
- Stacked bar or column charts take `dataLabelPosition` `ctr`, `inEnd` or `inBase` only (checked).
- A combo series on a secondary axis needs both `valAxes` and `catAxes`, two entries each (checked); otherwise PowerPoint drops the chart.
- An `&` in `pres.company` or a layout `title` is written unescaped: write `&amp;` there (and in the matching `masterName`).
- One `new pptxgen()` per output file.
- Do not reorder the children of `ppt/presentation.xml` after writing; PowerPoint opens the order `pptxgenjs` writes.
- `pptx_check.py` warns that `[Content_Types].xml` names a slide master that does not exist: `pptxgenjs` always writes that entry, and PowerPoint ignores it.
