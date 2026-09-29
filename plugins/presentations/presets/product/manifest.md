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
- `slides/`, all built from the layout grammar, none adapted from the default layouts: TitleSlide (product name at hero size on a band rule), SectionDivider (title on the rule, the deck's sections as a ruled tracker), ContentSlide (spec rows: name, what it does, the number), BarChartSlide (columns over releases in a panel with a header strip and a drop bracket), StatSlide (hero number plus one full-width stacked strip of the week), ClosingSlide (the ask, a full-width terminal panel with the command, next steps in ruled cells), and the signature slides ScreenshotSlide (HTML UI frame bleeding off the canvas, callouts with accent leader lines and rings), MetricsRowSlide (one lead metric over six columns, three supporting metrics, deltas), BeforeAfterSlide (old and new flow step by step on one duration scale), RoadmapSlide (Now, Next, Later columns), ChangelogSlide (dated ruled rows with mono version numbers). Each embeds a synced copy of the variable files and makes no network request. Added on 2026-09-29 from the reference slide decks research (composition and technique only; no text, data, or marks copied), continuing the same Relay 3 story:
  - BentoFeatureSlide: the launch recap as ten abutting ruled cells, the run page as an elevated hero panel in columns 5 to 8 across two rows, the lead claim above it in the accent, numbers and features around it; after Apple's September 2022 event summary bento slides.
  - SixTwelveSlide: CI hours at two zoom levels in one panel, six weeks left and twelve months right on their own scales, this year in the accent, the year before and the target in gray, six box scores in a ruled row beneath; after the Amazon Weekly Business Review 6-12 chart as rendered by Commoncog and the WBR app.
  - UnitTallySlide: the headline count at hero size, then two nested subsets as numbers and as one dot per repository, the subset the title names in the accent; after Palantir's Q1 2023 business update, page 17.
  - NorthStarTreeSlide: four ruled input cells with today's values in columns 1 to 7, a bracket in column 8, the one metric in an elevated panel in columns 9 to 12; after the Amplitude North Star Playbook worked example (page 31).
  - EfficiencyCurveSlide: two curves on L-shaped axes with no ticks or numbers, each axis naming its measure and which way is better, only the new release in color, labels at the curve ends; after Apple's M1 performance-against-power keynote frame (November 2020).
  - BenchmarkTableSlide: five named tests against three fictional rivals, task in plain words over the mono test name, the own column lifted onto `--bg-elev` with its values in the accent; after the benchmark table on Anthropic's Claude 3 launch page.
  - ThresholdTrendSlide: four survey waves as one line in the accent with each value at title size on an elbow leader, a dashed 40% bar named at its end, a ring where the line crosses it; after Superhuman's product-market fit results chart (First Round Review).
  - GuidanceSlide: Q3 and full-year expectations as two ruled cells with the same three rows, label over range, the range the title names in the accent; after Palantir's Q1 2023 business update, page 21.
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
- Library additions (2026-09-29). BentoFeatureSlide keeps the title band the Apple slides lack, turns the rounded floating tiles into ruled cells on column lines, and drops the icons (the preset has no `icons/` library and icon-topped cards are banned); it holds ten cells, not 12 to 16, and sets its numbers at 72px rather than 96px so the slide keeps three text sizes. At about 60 words it runs over the 50-word guide, as a recap of a whole release may. The accent marks only the lead claim, not a key word in every tile. SixTwelveSlide plots CI hours (a sum), not a median, so the weekly and monthly totals differ by about 4x and the two scales the reference uses are honest; values print on every other point, ending on the last, so they hold 28px; the reference's nine box scores become six and its legend becomes end labels; the target shows from April, when the beta set it. UnitTallySlide sets the threshold words in `--fg` against `--fg-muted` instead of the reference's underline (V6), and drops its pill tag and uppercase section label; it uses the hero size (240px) for the count and 128px for the subsets. NorthStarTreeSlide follows the playbook's worked example (inputs left, metric right), not the vertical framework page; the star glyph is dropped and the accent marks the metric statement, so the connector stays gray. EfficiencyCurveSlide keeps the reference's axes without numbers; its curves carry normalized points in `data-series` so the slide still renders from data, and the header strip and footer name the benchmark and the arithmetic behind the title (the reference was criticised for hiding its benchmark). BenchmarkTableSlide uses fictional products (Kestrel 5, Marlin CI, Plover 2) and fictional test names; the reference's outline around the own family becomes the one lifted column, per-cell method notes move to the header cell and the footer, and 70 cells become 20. Relay 3 loses the cold-build row, so the title claims four of five. ThresholdTrendSlide drops the legend and emojis, labels the bar at its end, and places each value below the line while the score is under the bar and above it once over, so no label crosses the bar. GuidanceSlide drops the reference's arrows and its "For ... we expect" lead lines.
- The 2026-09-29 slides extend the story and stay consistent with it: weekly CI hours for the 14 teams run 372 to 358 (14 x 26 = 364), monthly totals fall from 3,890 in March to 1,690 and 1,590, the target of 450 hours a week is half the Relay 2.4 level (14 x 64 = 896), and the box scores follow from those series (May on May 2025 3,710 to 1,590 is 57% down; Q2 7,400 to 3,280 is 56%; January to May 18,400 to 12,900 is 30%); 84 of the 120 repositories halved their median CI time and 23 of those cut it by three quarters; the benchmark's typical pull request (9.0 min) and affected tests (3.0 min) match the median run and the run page; 2.4 times the pull requests an hour and 38% of the spend follow from 22 to 9 minutes and $0.37 to $0.14; the bento's run page adds up to 6m 54s as on ScreenshotSlide.

## Fonts

| Family     | Files                                 | Source                                                                                               | License                        | Size  |
| ---------- | ------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------ | ----- |
| Geist      | `geist/Geist-Variable.woff2`          | npm `geist@1.7.2`, `dist/fonts/geist-sans/Geist-Variable.woff2`, fetched 2026-09-28 via jsDelivr     | OFL-1.1, no Reserved Font Name | 70 KB |
| Geist Mono | `geist-mono/GeistMono-Variable.woff2` | npm `geist@1.7.2`, `dist/fonts/geist-mono/GeistMono-Variable.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 70 KB |

`geist/OFL.txt` and `geist-mono/OFL.txt` are the package's `LICENSE.txt`. The files are unmodified.

## Gaps

- Not yet built on the ruled page (consumers adapt the default preset's structure): agenda, executive summary, statement, chart with insight, waterfall, 2x2 matrix, process, diagram (architecture, sequence, data flow), code, quote, and full-bleed image. Comparison is covered by BeforeAfterSlide, timeline by RoadmapSlide and ChangelogSlide, the dashboard by MetricsRowSlide and SixTwelveSlide, a table by BenchmarkTableSlide, and a metric tree by NorthStarTreeSlide.
- Reference slides held until seen first-hand (gated behind a membership): LogoWallMetricSlide, TwoPathClosingSlide, and TestimonialPairSlide from Linear's 2023 sales deck. Alternates not yet built: NumberProvedByChart, SegmentPanels, HighlightsList, ProofMosaic, ThresholdPies, HubSatellites, CohortRetention, MaturityMap, DecisionsRequired, OwnerPriorities.
- The 2026-09-29 slides show no build steps, like the rest of the gallery.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
