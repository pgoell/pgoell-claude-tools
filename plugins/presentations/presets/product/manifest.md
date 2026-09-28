# Preset: product

## Who this serves

Tech launches, product reviews, and engineering all-hands. Short declaratives about what the product does, with the number. All copy in the example slides is fictional placeholder content for an invented "Relay 3" build tool launch.

## Sources

- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset C, plus "Layout catalog" and "Wording rules for `language.md`").
- Grounding cited by the report: near-achromatic product systems with one rationed accent (Vercel Geist, Linear) and the IBM Carbon categorical data-visualization palette, with two entries adjusted after a color-blindness simulation.
- Before and after title pairs in `language.md` adapt examples quoted in the report from AECharts and Deckary, plus rewrites from this preset's own gallery story.

## Coverage

- `colors.css`: light and near-black `.dark` scopes with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, and six Carbon-ordered categorical colors per scope; the type scale (72px action title, 40px body); spacing, radius, shadows, and motion as in the default preset.
- `typography.css`: Geist for titles and body, vendored; Geist Mono named for code blocks only.
- `guidelines.md`, `language.md`: voice, skeleton, and the ten wording rules with the product tone line.
- `slides/`: TitleSlide, SectionDivider, ContentSlide, BarChartSlide (highlight mode), StatSlide, ClosingSlide. Each embeds a synced copy of the variable files and makes no network request.
- `assets/fonts/`: the vendored font file with its license.

## What this direction avoids

Near-achromatic grays with one signal-orange accent and Geist; avoids the purple-and-gradient launch deck, mono caps labels, and icon-topped feature cards.

## Decisions

- Charts default to highlight mode (the accent against `--chart-context`), so `--chart-highlight` points at `--accent`, not at the Carbon purple in `--chart-1`.
- Carbon light `#005D5D` and `#198038` became `#0C5C57` and `#028229` (the report's protanopia fix); the dark Carbon set is unchanged.
- Geist comes from Vercel's own `geist` npm build rather than the Google Fonts version, which the report notes has a limited glyph set.
- Geist Mono is not vendored: slides never use it. A deck with code blocks vendors it next to the deck.
- The type scale sits in `colors.css`, as the preset contract asks. The dark scope redeclares `--border-accent` and `--chart-highlight`.

## Fonts

| Family | Files                        | Source                                                                                           | License                        | Size  |
| ------ | ---------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------ | ----- |
| Geist  | `geist/Geist-Variable.woff2` | npm `geist@1.7.2`, `dist/fonts/geist-sans/Geist-Variable.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 70 KB |

`geist/OFL.txt` is the package's `LICENSE.txt`. The file is unmodified.

## Gaps

- Not yet built from the catalog for this voice: agenda, executive summary, statement, chart with insight, waterfall, table, comparison, 2x2 matrix, process, timeline, diagram, quote, full-bleed image, capabilities, and a dashboard of four to six tiles.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
