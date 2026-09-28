# Preset: editorial

## Who this serves

Data stories, research readouts, and reports presented as decks. A newsroom chart grammar on tinted paper. All copy in the example slides is fictional placeholder content for an invented "Brenford" cycling readout.

## Sources

- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset D, plus "Layout catalog" and "Wording rules for `language.md`").
- Grounding cited by the report: a tinted paper ground with a claret accent and a slate inverse, the Economist chart grammar (headline, subtitle with units, source line, horizontal gridlines only, direct labels), and serif titles legible at size. The values deliberately differ from the Financial Times' own colors.
- Before and after title pairs in `language.md` adapt examples quoted in the report from Perceptis, Zelazny, and AECharts, plus rewrites from this preset's own gallery story.

## Coverage

- `colors.css`: tinted-paper light scope and a slate `.dark` scope with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, and five categorical colors per scope; the type scale (72px headline, 48px chart subtitle, 40px body, 30px chart labels).
- `typography.css`: Newsreader for titles and Source Sans 3 for everything else, both vendored.
- `guidelines.md`, `language.md`: voice, chart grammar, and the ten wording rules with the editorial tone line.
- `colors.css` also carries the page grid and rule tokens (`--grid-col`, `--grid-gutter`, `--span-2` to `--span-5`, `--rule-hair`, `--rule-figure`, `--rule-zero`) that the layout grammar in `guidelines.md` uses.
- `slides/`, built from this preset's own layout grammar, not adapted from the default:
  - TitleSlide: report front page, masthead line under a double rule, headline, standfirst, byline.
  - SectionDivider: magazine section opener, part name hanging in column one, headline and standfirst in columns two to six.
  - ContentSlide: points as paragraphs parted by hairlines in the four-column measure, a slope chart as margin figure in columns five and six.
  - BarChartSlide: column chart with gridline labels on their lines, ink zero line, one annotation beside the story column.
  - StatSlide: serif figure with its sentence, and a dot strip (2022 against 2025) showing where the figure comes from.
  - ClosingSlide: the decision as headline, its consequence as standfirst, a three-column colophon (data, author, contact).
  - AnnotatedLineChartSlide: two quarterly series, story in the accent, context in gray, end labels, an event marker and two notes on the data.
  - SmallMultiplesSlide: 3 x 2 panels on one shared scale, corridor in the accent against the painted-corridor average in gray.
  - PullQuoteSlide: serif quote in columns two to six, hanging quote mark, speaker and context under a short rule.
  - ColumnsSlide: serif lede over three text columns with column rules.
  - TableSlide: editorial table, ink rule on top, right-aligned tabular figures, one tinted row, a hairline before the totals.
- Each slide embeds a synced copy of the variable files and makes no network request. The example numbers form one consistent fictional dataset (six protected corridors summing to 4k, 5k, 9k, 12k winter trips a day; four painted corridors at about 3k).
- `assets/fonts/`: the vendored font files with their licenses.

## What this direction avoids

Tinted paper, a serif headline, and one claret accent in a newsroom chart grammar; avoids both the off-white sans default and the warm-cream serif deck with a terracotta accent, and does not copy any newspaper's brand colors.

## Decisions

- `--chart-5` (`#B8860B`, 2.98:1 on the paper) stays below 3:1 as the report specifies, so it only appears with a direct label on every mark.
- `--accent-partner` keeps the report's first-draft values because it is never charted next to `--chart-4`.
- Newsreader ships as the Fontsource latin file with both the weight and optical-size axes, so titles get the display cut. Source Sans 3 ships as Adobe's own unmodified variable file, not a Fontsource subset, because it carries the Reserved Font Name "Source".
- The type scale sits in `colors.css`, as the preset contract asks. The dark scope redeclares `--border-accent` and `--chart-highlight`.
- Layout grammar (2026-09-28 rebuild): a six-column newspaper grid instead of the default's 12-column soft guide, because text columns and margin figures need whole-column widths. Sources sit in the footer on every slide rather than under each figure, so they stay in one place across the deck (language rule 9). Title, divider, pull quote, and closing use the slate scope per V9; their structure (masthead, hanging part name, hanging quote mark, colophon) also sets them apart.
- The accent marks the story in each figure only: the highlighted column, line, dot, figure, or table cell. The StatSlide figure is set in the accent because it is that slide's story value.

## Fonts

| Family        | Files                                           | Source                                                                                                                   | License                              | Size   |
| ------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------ | ------ |
| Newsreader    | `newsreader/Newsreader-Variable.woff2`          | npm `@fontsource-variable/newsreader@5.3.0`, `files/newsreader-latin-opsz-normal.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name       | 132 KB |
| Source Sans 3 | `source-sans-3/SourceSans3VF-Upright.ttf.woff2` | GitHub `adobe-fonts/source-sans` release `3.052R`, `WOFF2/VF/`, fetched 2026-09-28 via jsDelivr                          | OFL-1.1, Reserved Font Name "Source" | 170 KB |

Each family directory carries its `OFL.txt`, copied from the same source. Files are unmodified; do not subset Source Sans 3.

## Gaps

- Still adapted from the default preset when needed: agenda, executive summary, statement, chart with insight, comparison, timeline, full-bleed image, and the appendix divider the report lists as a gap.
- StatSlide uses four text sizes (hero figure, headline, sentence, strip labels), one over the three-size guide, as the default StatSlide does.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
