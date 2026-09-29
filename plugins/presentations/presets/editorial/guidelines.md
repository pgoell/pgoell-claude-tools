# Guidelines: editorial preset

## Voice

A good newspaper's data desk: a headline that says what the data shows, a plain subtitle with the units, and a source under every chart.

## Use it for

Data stories, research readouts, policy briefings, and reports presented as decks. It reads well both projected and as a PDF.

## Skeleton

- Margins 96px at the sides, 80px at the top, on the six-column page grid described under Layout grammar. Sentence headline top left at `--fs-h1` (72px), at most two lines.
- Every chart carries a standfirst at `--fs-subtitle` with units and dates.
- Footer: source and note line bottom left and plain page number bottom right, both at `--fs-micro`.
- Structure slides (title, section divider, pull quote, closing) use the slate `.dark` scope.

## Color

- The claret accent marks the story: the highlighted column, the line that matters.
- Chart grammar: horizontal gridlines only, in `--chart-grid`, lighter than the axis labels; the zero line in `--fg`; direct labels instead of legends; `--chart-highlight` for the story series and `--chart-context` for the rest. `--chart-5` needs a direct label on every mark.
- The tinted paper background narrows the lightness range; keep categorical charts to five series.

## Type

- Newsreader for titles and structure headings, Source Sans 3 for subtitles, body, labels, and source lines. Both set tabular figures by default.
- Titles stay at 72px or more because Newsreader's x-height is low.

## Imagery

Photographs and maps as reporting: they show the place or the thing the data measures, with a caption that says what it is.

## Layout grammar

The page of a newspaper or a weekly, not a consulting slide: FT and Economist graphics grammar, the NYT graphics desk's annotation habit, and Datawrapper's chart defaults (research report, "Editorial and data-journalism chart conventions").

- **Grid.** Six columns of 248px with 48px gutters inside the 96px side margins (6 x 248 + 5 x 48 = 1728), tokens `--grid-col`, `--grid-gutter`, `--span-2` to `--span-5`. Headlines span five columns (`--span-5`, 1432px). Running text spans four (`--span-4`, 1136px, about 55 to 60 characters at 40px). Text columns and margin figures span two (`--span-2`, 544px). Economist panels sit on fixed column widths with a fixed spacer; this is the slide version of that.
- **Title.** Serif sentence headline top left at 72px, same place on every content slide, then a sans standfirst at 48px in `--fg-muted` that carries the measure, units, and dates (Economist: "put units and date information on a second line"). No kicker or label above the headline.
- **Evidence.** Hangs from a 3px ink rule (`--rule-figure`) under the standfirst and runs the full 1728px unless it is a margin figure. Charts: horizontal gridlines only in `--chart-grid`, value labels sitting on top of their gridline at the left edge, a 4px ink zero line (`--rule-zero`, the heaviest line in the chart; Economist "use black for zero"), lines labelled at their ends, and one to three annotations written onto the data with thin leaders instead of value labels on every mark. Source and note line bottom left at 24px.
- **Density.** Presented slides about 20 to 50 words, a readout read alone up to 75; one figure per slide, or one figure repeated as small multiples on a shared scale. Density comes from panels, tables, and annotation, never from smaller type.
- **Whitespace.** Paper, not a canvas: text blocks are centered in the space below the headline so no dead band opens at the foot; charts fill the width. Structure slides leave the empty space above the headline, the way a section opener does.
- **Signature moves.** (1) The ink rule over every figure and the gridline label sitting on its line. (2) Annotations placed on the data (AnnotatedLineChartSlide, the column note on BarChartSlide). (3) Text set in newspaper columns with column rules and a serif lede (ColumnsSlide, ContentSlide's margin figure, the closing colophon). (4) Front-page and section-opener structure: a masthead under a double rule on the title, the part name hanging in column one on the divider and the quote mark hanging in column one on the pull quote.
- **Never.** No cards, boxes, shadows, or icon rows; no vertical gridlines, legend boxes, or value labels on every bar; no bullets (points are short paragraphs parted by hairlines); no centered body text; no red tab, salmon ground, or any newspaper's own marks; no italic or accent words in headlines.

## Layouts

Built in `slides/`: TitleSlide, SectionDivider, ContentSlide, BarChartSlide, StatSlide, ClosingSlide, plus the signature layouts AnnotatedLineChartSlide, SmallMultiplesSlide, PullQuoteSlide, ColumnsSlide, and TableSlide, and the library layouts ChartSidebarSlide (serif reading in a sidebar beside a column chart), HighlightedGroupBarsSlide (grouped bars on one axis, the latest year in the accent in every group), RankedBarsSlide (sorted bars, one in the accent, values at bar ends), RescaleRevealSlide (grouped columns, then the same chart rescaled by one added group, in one file), QuotePairSlide (two serif quotes in adjacent spans with a column rule), KeyFindingsSlide (part names hanging in column one over one-line findings), PredictionScorecardSlide (forecast, verdict, and outcome in hairline rows), and DivergingBarsSlide (gains above and losses below a heavy zero line). KeyFindingsSlide serves as the executive summary. For other roles (agenda, timeline, comparison, full-bleed image, appendix divider), take the structure from the default preset and set it on this grid and rule system.
