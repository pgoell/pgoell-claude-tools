# Guidelines: analytical preset

## Voice

Calm, exact, and decision-oriented. Every content slide makes one claim and shows the evidence for it. The look stays out of the way: white paper, navy ink, one blue accent.

## Use it for

Decks read by or presented to decision makers: board papers, steering committees, strategy reviews, business cases. Choose it when the deck will be read without the presenter in the room.

## Skeleton

- Margins 96px at the sides. The action title sits top left at `--title-top` (120px), at `--fs-h1` (60px), in the same place on every content slide, at most two lines. See Layout grammar below for the full grid.
- A typical content slide uses three sizes: title 60px, body 36px, source 24px.
- Exhibit subtitle at the top of the evidence area, at `--fs-body` in `--fg-muted`, names the measure, its units, and its dates.
- Footer: source line bottom left, plain page number bottom right, both at `--fs-micro`. No rule, no slide counter.
- Sticker top right ("Preliminary", "Illustrative") at `--fs-caption`, sentence case, only when the numbers carry that status.
- Structure slides (title aside) use the navy `.dark` scope: section divider and closing. They carry no footer and no tracker.

## Color

- `--accent` blue marks the one thing to look at: the highlighted bar, the row the title names, the current section.
- Charts run gray plus one: `--chart-highlight` for the story series, `--chart-context` for the rest. Use `--chart-1` to `--chart-6` in order only when the categories are the point, and label every series directly.
- Borders are decorative and never carry meaning.

## Type

- IBM Plex Serif 600 for titles and structure headings, IBM Plex Sans for everything else. Numbers always in Plex Sans, which sets tabular figures by default.
- No tracked uppercase, no italic accent words, no mono labels.

## Imagery

Evidence only: a map, a site photo, a screenshot that proves the claim. No stock photos, no decorative icons.

## Layouts

Covered by the catalog for this voice: title, agenda, section divider, executive summary, content, big number, chart with insight, bar chart, waterfall, table, comparison, 2x2 matrix, process, timeline, issue tree, quote, capabilities, closing. Skip full-bleed image and single-statement slides.

## Layout grammar

Consulting document grammar (McKinsey, BCG, Bain): slides are read alone, so structure does the work and whitespace is what is left over. Sources are the consulting sections of the presentation design systems report (Deckary, Slideworks, MConsultingPrep, StrategyU, Advisio, Poesius, BrightCarbon, and the measured McKinsey and BCG decks).

### Grid

- 12 columns of 122px with 24px gutters between 96px side margins (`--grid-col`, `--grid-gutter`, `--slide-pad-x`). BrightCarbon recommends 12 columns for 16:9; measured margins run 84px (BCG) to 96px (Duarte slidedocs).
- Every block starts and ends on a column edge. Common splits: 7 + 5 (the 60/40 chart and takeaway, Poesius), 5 + 1 + 6 (number and its arithmetic), 3 + 7 + 2 (lead, evidence, figure), 2 + 10 (row label and text).

### Fixed chrome

Positions never move from slide to slide ("titles should not move when you flip through the deck", Deckary; "same elements on different slides at the exact position", MConsultingPrep).

| Element       | Position                                                  | Size                   |
| ------------- | --------------------------------------------------------- | ---------------------- |
| Tracker       | top left at `--tracker-top` (48px), 2 columns per section | `--fs-micro`           |
| Sticker       | top right at `--tracker-top`, bordered                    | `--fs-caption`         |
| Action title  | top left at `--title-top` (120px), 11 columns wide        | `--fs-h1`, max 2 lines |
| Evidence area | from `--body-top` (300px) to 124px above the bottom edge  | any                    |
| Source, page  | bottom left and bottom right, 48px from the bottom        | `--fs-micro`           |

- The tracker lists the deck's sections in order, each with a 4px rule over its name; the current section's rule is the accent and its name is `--fg` semibold. Use it on every content slide inside a section; leave it off the title, executive summary, and structure slides.
- The sticker appears only when the numbers carry that status: "Preliminary", "Illustrative", "For discussion", "Draft for discussion".
- The evidence area starts at the same height whether the title runs one line or two.

### Density

- Target 40 to 75 words per content slide (the reading-deck range in `language.md`), up to 30 layout units, three type sizes (title 60px, body 36px, captions 28px) plus the footer.
- Density comes from structure: rows with rules between them, tables, trees, and Gantt lanes. Never from smaller type.
- Whitespace stance: no deliberate empty bands. Leftover space sits at the bottom of the evidence area, not between title and evidence.

### Signature moves

1. **Tracker plus sticker** on the top row of every content slide.
2. **Ruled rows**: evidence set as horizontal rows with a label column on the left, a 2px `--fg` rule on top and `--border` or `--border-strong` rules between rows (content, executive summary, scorecard, next steps).
3. **Bordered takeaway box**: a 2px `--fg` box holding the so-what beside the exhibit, in the 5 right-hand columns.
4. **Shown arithmetic**: every headline number sits next to the sum that makes it (a bridge on the stat slide, a yearly saving column on the issue tree, page references on the executive summary).

### Structure slides

- Title: white, left aligned, no hero art. Client name top left, sticker top right, the claim at `--fs-display`, and a ruled document block (prepared for, date, prepared by) on the grid.
- Section divider: navy, the full agenda repeated with the current section grown to `--fs-section` under an accent rule, page references on the right.
- Closing: navy, a decision and a next-steps table (step, owner, date), with the decision asked of this meeting in the accent. Never a slogan or "Thank you".

### Never

- Centered body text, full-bleed photos, single-statement slides, decorative icons.
- Legends where a direct label fits; more than one accent job per slide.
- Titles that move, shrink, or run past two lines.

### Layouts built for this grammar

TitleSlide, ExecSummarySlide (SCQA rows with bold lead phrases and page references), ContentSlide (3 ruled rows: lead, evidence, figure), BarChartSlide (all categories, reference line, value column, bracket), ChartTakeawaySlide (60/40 with bordered box), SectionDivider, IssueTreeSlide (MECE tree in SVG), StatSlide (number plus bridge), ScorecardSlide (Harvey balls), ProcessSlide (phase chevrons over workstream lanes), ClosingSlide (decision plus next steps).
