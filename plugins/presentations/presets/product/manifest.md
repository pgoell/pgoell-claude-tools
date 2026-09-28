# Preset: product

## Who this serves

Tech launches, product reviews, and engineering all-hands. Short declaratives about what the product does, with the number. All copy in the example slides is fictional placeholder content for an invented "Relay 3" build tool launch.

## Sources

- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset C, plus "Layout catalog" and "Wording rules for `language.md`").
- Grounding cited by the report: near-achromatic product systems with one rationed accent (Vercel Geist, Linear) and the IBM Carbon categorical data-visualization palette, with two entries adjusted after a color-blindness simulation.
- Before and after title pairs in `language.md` adapt examples quoted in the report from AECharts and Deckary, plus rewrites from this preset's own gallery story.

## Coverage

- `colors.css`: light and near-black `.dark` scopes with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, and six Carbon-ordered categorical colors per scope; the type scale (72px action title, 40px body); spacing, radius, shadows, and motion as in the default preset.
- `colors.css` also carries the ruled-page layout tokens (`--grid-col`, `--cell-pad`, `--band-title`, `--band-foot`) and two display tracking steps (`--tracking-display`, `--tracking-hero`).
- `typography.css`: Geist for titles and body and Geist Mono for commands and identifiers, both vendored.
- `guidelines.md`: voice, color, type, imagery, and the `## Layout grammar` (the ruled page: rails, band rules, crosshairs, 12 columns of 144px, cells versus elevated panels, density, signature moves, and what the preset never does), plus a role-to-layout table.
- `language.md`: the ten wording rules with the product tone line.
- `slides/`, all built from the layout grammar, none adapted from the default layouts: TitleSlide (product name at hero size on a band rule), SectionDivider (title on the rule, the deck's sections as a ruled tracker), ContentSlide (spec rows: name, what it does, the number), BarChartSlide (columns over releases in a panel with a header strip and a drop bracket), StatSlide (hero number plus one full-width stacked strip of the week), ClosingSlide (the ask, a full-width terminal panel with the command, next steps in ruled cells), and the signature slides ScreenshotSlide (HTML UI frame bleeding off the canvas, callouts with accent leader lines and rings), MetricsRowSlide (one lead metric over six columns, three supporting metrics, deltas), BeforeAfterSlide (old and new flow step by step on one duration scale), RoadmapSlide (Now, Next, Later columns), ChangelogSlide (dated ruled rows with mono version numbers). Each embeds a synced copy of the variable files and makes no network request.
- `assets/fonts/`: the vendored font files with their license.

## What this direction avoids

Near-achromatic grays with one signal-orange accent and Geist; avoids the purple-and-gradient launch deck, mono caps labels, and icon-topped feature cards.

## Decisions

- Charts default to highlight mode (the accent against `--chart-context`), so `--chart-highlight` points at `--accent`, not at the Carbon purple in `--chart-1`.
- Carbon light `#005D5D` and `#198038` became `#0C5C57` and `#028229` (the report's protanopia fix); the dark Carbon set is unchanged.
- Geist comes from Vercel's own `geist` npm build rather than the Google Fonts version, which the report notes has a limited glyph set.
- Geist Mono is vendored (2026-09-28 layout rebuild): the closing command, the UI frame URL, and changelog version numbers use it. It stays limited to literal identifiers at 28px or larger, so it never becomes a mono micro label.
- The grid has no gutters: hairlines sit on 144px column lines and text insets 32px, the bordered-cell structure of the Vercel and Linear web systems. The rails and band rules draw in a layer above the content (`.ruled::before`) so a lifted cell never hides them.
- MetricsRowSlide gives the lead metric six columns and a 240px number and the others two columns at 72px. Equal tiles in a banner row are a documented slop tell (and copy-lint K3); the uneven row keeps one focal point.
- The UI frame is HTML, not a raster, so it restyles with the tokens and stays legible at the 28px caption floor; it is a mock of an invented product and must be replaced with a real screenshot, cropped to the feature, in a real deck.
- Example content is one consistent invented story: 120 beta repositories across 14 teams; median CI 22 to 9 min (Relay 2.4 to 3), p95 48 to 21 min, cost per run $0.37 to $0.14, cache hit rate 81%, affected tests 23% of the suite (312 of 1,380), team CI time 64 to 26 hours a week (38 back); step times 3+6+11+2 = 22 and 1+2+4+2 = 9.
- The type scale sits in `colors.css`, as the preset contract asks. The dark scope redeclares `--border-accent` and `--chart-highlight`.

## Fonts

| Family     | Files                                 | Source                                                                                               | License                        | Size  |
| ---------- | ------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------ | ----- |
| Geist      | `geist/Geist-Variable.woff2`          | npm `geist@1.7.2`, `dist/fonts/geist-sans/Geist-Variable.woff2`, fetched 2026-09-28 via jsDelivr     | OFL-1.1, no Reserved Font Name | 70 KB |
| Geist Mono | `geist-mono/GeistMono-Variable.woff2` | npm `geist@1.7.2`, `dist/fonts/geist-mono/GeistMono-Variable.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 70 KB |

`geist/OFL.txt` and `geist-mono/OFL.txt` are the package's `LICENSE.txt`. The files are unmodified.

## Gaps

- Not yet built on the ruled page (consumers adapt the default preset's structure): agenda, executive summary, statement, chart with insight, waterfall, table, 2x2 matrix, process, diagram (architecture, sequence, data flow), code, quote, and full-bleed image. Comparison is covered by BeforeAfterSlide, timeline by RoadmapSlide and ChangelogSlide, the dashboard by MetricsRowSlide.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
