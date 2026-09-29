# Preset: analytical

## Who this serves

Consulting-style decks read by or presented to decision makers: board papers, steering committees, strategy reviews, and business cases. The voice is claim plus number. All copy in the example slides is fictional placeholder content for an invented "Kestrel Logistics" depot review.

## Sources

- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset A, plus "Layout catalog" and "Wording rules for `language.md`"). Every hex value there is a design derivation and every ratio a WCAG 2.x computation; this preset re-checked both.
- Grounding cited by the report: navy plus white plus one accent in consulting identities, a serif title over a sans body, a title-to-body ratio near the 1.71 median measured across 27 public McKinsey, BCG, and Bain decks, and ColorBrewer Blues and RdBu for sequential and diverging scales.
- Before and after title pairs in `language.md` adapt examples quoted in the report from Perceptis, Deckary, and Zelazny, plus rewrites from this preset's own gallery story.

## Coverage

- `colors.css`: layout grid tokens (`--grid-col`, `--grid-gutter`, `--tracker-top`, `--title-top`, `--body-top`, `--body-bottom`), semantic light scope (white paper, navy ink, blue accent) and a navy `.dark` scope with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, six categorical colors per scope, plus `--chart-seq-1` to `--chart-seq-5` (ColorBrewer Blues 5) and `--chart-div-1` to `--chart-div-5` (ColorBrewer RdBu 5); the slide type scale (60px action title, 36px body, 24px source line); spacing, radius, shadows, and motion as in the default preset.
- `typography.css`: IBM Plex Serif 600 for titles, IBM Plex Sans 400 and 600 for everything else, all vendored.
- `guidelines.md`: voice, use, skeleton (margins, footer with page number, sticker), color, type, imagery, and layout coverage.
- `language.md`: the ten wording rules with the analytical tone line, the facts rule, and before and after pairs.
- `slides/`: 11 base layouts built from the layout grammar in `guidelines.md`, not adapted from `default`: TitleSlide, ExecSummarySlide, SectionDivider, ContentSlide, BarChartSlide, ChartTakeawaySlide, IssueTreeSlide, StatSlide, ScorecardSlide, ProcessSlide, ClosingSlide. They tell one consistent story (Kestrel depot review: €129M cost to serve, 3 depots at €40M, €22M added elsewhere, €18M net). Each embeds a synced copy of the variable files and makes no network request.
  - GapToTargetSlide: after McKinsey's USPS 2010 slide 28; cost to serve 2021 to 2028 with an actual and forecast divider, no-action and planned-actions lines in two grays under a dashed 2028 target, the €18M gap shaded in the accent, and three line-keyed notes in columns 8 to 12 read in story order.
  - ChartTripletSlide: two slides in one file. The triplet follows BCG's Dallas 2016 slide 8 (and McKinsey's USPS slide 27): three 4-column panels, each a claim sub-headline, a rule, a unit line, and one small bar chart with one accent bar. The panel pair follows Dallas slides 13 and 20: two 6-column panels whose sub-headlines join by an ellipsis, rows aligned across both charts in the same depot order.
  - ScenarioFanSlide: after BCG's Dallas 2016 slide 9 and Bain's Con Edison 2018 summary p4; lettered levers in columns 1 to 4, a capacity history splitting into three dashed paths, a 2030 end column, a shaded over-capacity wedge with one callout, and the recommended path in the accent.
  - SensitivityGridSlide: after McKinsey's UK electricity efficiency 2012 p21; a 3x3 grid of single bars against a base-case tick, base cell tinted, the worst case in the accent, and a bordered takeaway box.
  - TargetsRowSlide: after the Rolls-Royce Capital Markets Day 2023 strategic update p10; four KPI columns, each a target figure over 2024, 2025, and an outlined target bar with a dotted delta bracket.
  - PrioritizationMatrixSlide: after BCG's Dallas 2016 slide 26; tapering impact and effort wedges, five panels (three over two) with start-order discs and levers with their yearly saving, the first panel in the accent.
  - FundingBridgeSlide: after BCG's Dallas 2016 slide 28; a one-off cost waterfall ending in a total bar stacked by who pays, labelled at the right, dashed boxes for ranges, and the implication in a bordered box.
  - RecommendationsSlide: after BCG's Dallas 2016 slide 24; three grouping bands spanning six numbered one-sentence recommendations with dashed rules, the "taken as a whole" line as the exhibit subtitle.
- The library slides (15 to 23) extend the same dataset: cost to serve €112M to €129M from 2021 to 2025, €151M in 2028 with no action and €133M after the €18M of other levers on the issue tree, against a €115M 2028 target (a €14M cut from 2025, and the €18M gap the closure fills); the scorecard's €12M one-off cost, paid €5M, €4M, and €3M; 2 added shifts per depot giving about 17% more capacity, which keeps the Friday peak at 84% at 2025 volumes; the 3 depots' 12% of parcels split 3.5, 4.0, and 4.5%.
- `assets/fonts/`: the vendored font files with their licenses.

## What this direction avoids

White paper, navy ink, and one blue accent with a serif title; avoids the off-white, lime, and sans-everything default and the purple-gradient AI deck.

## Decisions

- The type scale, line heights, tracking, and slide margins sit in `colors.css` next to the colors, as the preset contract asks; the report placed them in `typography.css`.
- `--chart-highlight` (set to `--accent`) was added to the report's chart group so every preset names its story-series color the same way.
- The dark scope redeclares `--border-accent` and `--chart-highlight` so they pick up the dark accent instead of inheriting the resolved light value.
- IBM Plex ships as IBM's own unmodified static files, not a Fontsource latin subset, because Plex carries a Reserved Font Name and subsetting counts as modification.
- The mono stack is not vendored: slides never use it.
- Layout rebuild (2026-09-28): the six base slides were copies of the `default` compositions with swapped variables. They are rebuilt on a 12-column consulting grid with fixed chrome (tracker, sticker, title, evidence area, source and page number), and five signature layouts were added. Grammar and sources are in `guidelines.md`, Layout grammar.
- Layout tokens were added to `colors.css` next to the spacing tokens; no color changed, so contrast figures stand.
- The tracker renders at `--fs-micro` (24px) and is marked `data-role="footer"`: it is navigation chrome like the page number, and the report sizes it with the footer.
- The section divider repeats the agenda with the current section grown, instead of a lone heading: consulting decks use the agenda as the divider.
- The closing slide is a decision plus a next-steps table on the navy scope, not a slogan.
- Charts keep their values in `data-*` attributes and draw in SVG from them; Harvey balls draw from `data-score` (0 to 4 quarters, full is best). The issue tree and the workplan are static inline SVG diagrams using CSS variables.
- Library additions (2026-09-29, from the reference slide decks report): every reference color key (red, orange, and green lines; colored lever chips; blue callout blocks) became grays by weight plus the one accent, and every in-chart legend became a direct label. The USPS breadcrumb and the Dallas green banners were dropped; implications sit in the preset's bordered box instead. Dallas's hand-drawn emphasis and all-caps phrases became weight. Recommendations were cut from seven to six rows and triplet panels hold five bars so text stays at 36px and 28px. The panel pair keeps depot names on the left chart only; the right chart shares its rows. The prioritization panels use lever names, not initiative codes, because the gallery has no code list to point at, and the impact wedge is thin so the panels keep whole columns. TargetsRowSlide brackets the change from 2025 (the latest actual) to the target, where Rolls-Royce brackets from the first year, so the bracket matches the title; its target figures are a 52px size, so the slide drops the exhibit subtitle to stay at three sizes and puts units in each KPI label. The target shows as an outline, not the reference's gradient fade.
- ChartTripletSlide ships the triplet and the panel pair as two `<section>` elements in one file, stacked in a 1920x2160 frame for standalone viewing, as editorial's RescaleRevealSlide does. No new slide uses build steps.
- Nothing on the iteration-2 shortlist was skipped. Iteration-1 picks NextSteps, AgendaTracker, PeerBenchmark, and OptionVerdict stay dropped as duplicates of ClosingSlide, SectionDivider, BarChartSlide, and ScorecardSlide.

## Fonts

| Family         | Files                                                        | Source                                                                                | License                            | Size            |
| -------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------- | ---------------------------------- | --------------- |
| IBM Plex Serif | `ibm-plex-serif/IBMPlexSerif-SemiBold.woff2`                 | npm `@ibm/plex-serif@2.0.0`, `fonts/complete/woff2/`, fetched 2026-09-28 via jsDelivr | OFL-1.1, Reserved Font Name "Plex" | 73 KB           |
| IBM Plex Sans  | `ibm-plex-sans/IBMPlexSans-Regular.woff2`, `-SemiBold.woff2` | npm `@ibm/plex-sans@1.1.0`, `fonts/complete/woff2/`, fetched 2026-09-28 via jsDelivr  | OFL-1.1, Reserved Font Name "Plex" | 63 KB and 67 KB |

Each family directory carries its `OFL.txt`, copied from the same package. Files are unmodified; do not subset them.

## Gaps

- Still adapted from `default` (swap in this preset's variable blocks, then apply the fixed chrome and grid from the layout grammar): agenda (use the SectionDivider list with no section current), waterfall, table, comparison, 2x2 matrix, timeline, quote, capabilities.
- Report gaps still open for this voice: a dashboard of four to six tiles and an appendix divider. The Harvey-ball scorecard is now built.
- Shortlist alternates not yet built: FromTo, ObservationImplication, StakeholderAsks, CostCurve, ConvergenceFunnel, FactsPerspectives, ApproachPhases, BarrierHeatmap, ContributionStack, and ProjectionBand.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
