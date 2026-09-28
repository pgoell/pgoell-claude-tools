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
- `slides/`: 11 layouts built from the layout grammar in `guidelines.md`, not adapted from `default`: TitleSlide, ExecSummarySlide, SectionDivider, ContentSlide, BarChartSlide, ChartTakeawaySlide, IssueTreeSlide, StatSlide, ScorecardSlide, ProcessSlide, ClosingSlide. They tell one consistent story (Kestrel depot review: €129M cost to serve, 3 depots at €40M, €22M added elsewhere, €18M net). Each embeds a synced copy of the variable files and makes no network request.
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

## Fonts

| Family         | Files                                                        | Source                                                                                | License                            | Size            |
| -------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------- | ---------------------------------- | --------------- |
| IBM Plex Serif | `ibm-plex-serif/IBMPlexSerif-SemiBold.woff2`                 | npm `@ibm/plex-serif@2.0.0`, `fonts/complete/woff2/`, fetched 2026-09-28 via jsDelivr | OFL-1.1, Reserved Font Name "Plex" | 73 KB           |
| IBM Plex Sans  | `ibm-plex-sans/IBMPlexSans-Regular.woff2`, `-SemiBold.woff2` | npm `@ibm/plex-sans@1.1.0`, `fonts/complete/woff2/`, fetched 2026-09-28 via jsDelivr  | OFL-1.1, Reserved Font Name "Plex" | 63 KB and 67 KB |

Each family directory carries its `OFL.txt`, copied from the same package. Files are unmodified; do not subset them.

## Gaps

- Still adapted from `default` (swap in this preset's variable blocks, then apply the fixed chrome and grid from the layout grammar): agenda (use the SectionDivider list with no section current), waterfall, table, comparison, 2x2 matrix, timeline, quote, capabilities.
- Report gaps still open for this voice: a dashboard of four to six tiles and an appendix divider. The Harvey-ball scorecard is now built.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
