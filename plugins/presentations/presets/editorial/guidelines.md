# Guidelines: editorial preset

## Voice

A good newspaper's data desk: a headline that says what the data shows, a plain subtitle with the units, and a source under every chart.

## Use it for

Data stories, research readouts, policy briefings, and reports presented as decks. It reads well both projected and as a PDF.

## Skeleton

- Margins 96px at the sides, 80px at the top. Sentence headline top left at `--fs-h1` (72px), at most two lines.
- Every chart carries a subtitle at `--fs-subtitle` with units and dates.
- Footer: source line bottom left and plain page number bottom right, both at `--fs-micro`.
- Structure slides use the slate `.dark` scope.

## Color

- The claret accent marks the story: the highlighted column, the line that matters.
- Chart grammar: horizontal gridlines only, in `--chart-grid`, lighter than the axis labels; the zero line in `--fg`; direct labels instead of legends; `--chart-highlight` for the story series and `--chart-context` for the rest. `--chart-5` needs a direct label on every mark.
- The tinted paper background narrows the lightness range; keep categorical charts to five series.

## Type

- Newsreader for titles and structure headings, Source Sans 3 for subtitles, body, labels, and source lines. Both set tabular figures by default.
- Titles stay at 72px or more because Newsreader's x-height is low.

## Imagery

Photographs and maps as reporting: they show the place or the thing the data measures, with a caption that says what it is.

## Layouts

Covered by the catalog for this voice: title, agenda, section divider, executive summary, content, statement, big number, chart with insight, bar chart, table, comparison, timeline, quote, full-bleed image, appendix divider, closing.
