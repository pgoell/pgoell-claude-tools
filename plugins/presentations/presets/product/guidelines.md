# Guidelines: product preset

## Voice

Direct and concrete. Say what the product does and what changed, in short declarative sentences with the number. Parallel pairs are welcome when the pair is the point.

## Use it for

Product launches, release reviews, engineering all-hands, and roadmap updates. It suits screens and shared windows as well as rooms.

## Skeleton

The ruled page below is the skeleton. Structure slides (title, section divider, closing) use the near-black `.dark` scope and move the band rules, never drop them. No page numbers.

## Color

- The signal-orange accent is rationed: one mark per slide, on the thing that changed.
- Charts default to highlight mode: `--chart-highlight` (the accent) for the story series, `--chart-context` for the rest. The Carbon-ordered `--chart-1` to `--chart-6` serve only charts where the categories are the point, in strict order, with direct labels.
- No purple, no gradients, no glow.

## Type

- Geist throughout, in several weights. Geist Mono only for literal things people type or search for: commands, file names, URLs, channel names, version numbers. Never for labels or metadata, never under 28px.
- Tables, metrics, and chart labels use tabular figures. Display sizes tighten: `--tracking-tight` at 60 to 96px, `--tracking-display` at 128px, `--tracking-hero` at 240px.

## Imagery

Real product screenshots and diagrams of the real system, cropped to the part that proves the point. No device mockups for their own sake, no icon rows.

## Layout grammar

Grounded in the Vercel and Linear web systems (near-achromatic surfaces, bordered grid cells, one rationed accent, Geist with tight display tracking) and in Stripe Sessions keynotes (little text, the data or the product carries the slide). Sources: the 2026-09-28 presentation design systems report, "Tech and editorial" and Preset C; the Figma slide guide's 12 columns with 96px margins; the AI-slop catalogs (Developers Digest, Plus AI) for what to avoid.

**Grid: the ruled page.** Two vertical rails at x = 96 and x = 1823 bound 12 columns of `--grid-col` (144px); column n starts at 96 + (n-1) x 144. Two horizontal rules cut the page into a title band (0 to `--band-title`, 288px), an evidence band, and a footer band (`--band-foot`, 992px, to 1080). Rails and rules are 1px `--border-strong` hairlines, full bleed, drawn above the content so filled cells never hide them, with a 33px crosshair (`.x`, `--fg-subtle`) where a rule meets a rail. There are no gutters: every hairline sits on a column line, and text insets `--cell-pad` (32px) from the line it sits against, so neighboring text columns keep a 64px gap. Visible alignment is the point; nothing floats between lines.

**Title.** Top left at x = 128, y = 80, `--fs-h1` (72px) semibold, `--tracking-tight`, at most two lines within 1520px, the same place on every content slide. Short declaratives with the number; a parallel pair is fine when the pair is the claim.

**Evidence.** Fills the evidence band rail to rail, in one of two surfaces:

- Ruled cells (flat `--bg`, separated by 1px `--border`) carry text and numbers: spec rows, metric rows, roadmap columns, changelog rows. Cells abut; no floating cards, no gaps, no shadows.
- Elevated panels (`.panel`: `--bg-elev`, 1px `--border-strong`, `--r-lg` radius) carry product objects: UI frames, terminals, charts with a header strip naming the measure and sample. `--shadow-2` only on a UI frame.

One cell or column may be lifted onto `--bg-elev` to mark the current or new thing (the current section, the new flow, what ships now).

**Footer.** Source line in the footer band at x = 128, `--fs-micro`, only when the slide shows numbers. A slide whose evidence bleeds (a UI frame) gives the footer band up.

**Density.** Presented decks: about 20 to 40 words on a content slide, at most 50; a changelog or roadmap may reach about 60 because the structure carries it. Three to seven evidence elements (rows, cells, bars). At most three text sizes per slide: 72 title, 40 body, 28 caption, plus one of 96, 128, or 240 on structure, stat, and metric slides. Density comes from ruled rows at 40px, never from smaller type.

**Whitespace.** Empty space sits inside cells, not between floating blocks. A band may stay empty (the title band under a one-line title); a cell never holds a lone short line in a sea of space when a second fact from the source would fill it.

**Signature moves** (only this preset does these):

1. The ruled page: rails, band rules, and crosshairs on every slide, structure slides included.
2. Product UI as the hero: a window frame built in HTML from column 4, bleeding off the right and bottom edges, with callouts in columns 1 to 3 tied by accent leader lines to accent rings around the feature.
3. Uneven metric rows: one lead number at `--fs-hero` across six columns, the supporting numbers at 72px in two columns each, deltas ("was 22 min") under every number.
4. The command as the call to action: the closing slide puts the one thing to run in a full-width terminal panel with an accent border, and where to go next in ruled cells below.

**Never:** purple or gradients, glows, badges or pills above a title, icon-topped card rows, equal stat tiles in a banner row, colored left borders, drop shadows on text cells, centered hero text, device mockups for their own sake, mono caps labels, eyebrows.

## Layouts

| Role                                     | Layout                                                                              |
| ---------------------------------------- | ----------------------------------------------------------------------------------- |
| Opening: product name and one line       | TitleSlide                                                                          |
| Where the deck is                        | SectionDivider                                                                      |
| Claim backed by two to four features     | ContentSlide (spec rows)                                                            |
| Trend across releases                    | BarChartSlide                                                                       |
| One number is the message                | StatSlide                                                                           |
| The product itself proves the claim      | ScreenshotSlide                                                                     |
| Three or four metrics, one leads         | MetricsRowSlide                                                                     |
| Old flow against new flow                | BeforeAfterSlide                                                                    |
| What ships when                          | RoadmapSlide                                                                        |
| What shipped, dated                      | ChangelogSlide                                                                      |
| The ask: a command or URL to act on      | ClosingSlide                                                                        |
| A release recap: many features, one hero | BentoFeatureSlide (ruled cells around an elevated hero panel)                       |
| A metric at two zoom levels              | SixTwelveSlide (six weeks beside twelve months, box scores beneath)                 |
| A count and the subsets inside it        | UnitTallySlide (hero number, then one dot per item)                                 |
| Inputs that drive the one metric         | NorthStarTreeSlide (four input cells bracketed into an elevated metric panel)       |
| Better on two measures at once           | EfficiencyCurveSlide (two curves on unnumbered axes, only the new release in color) |
| Named tests against rivals               | BenchmarkTableSlide (own column lifted, its values in the accent)                   |
| A trend crossing a threshold             | ThresholdTrendSlide (one accent line, a dashed bar, a ring at the crossing)         |
| What to expect next                      | GuidanceSlide (two ruled cells of ranges, the named range in the accent)            |

For any other catalog role (agenda, process, diagram, quote, image), take the structure from the default preset and set it on the ruled page: title in the title band, evidence in ruled cells or one panel, source in the footer band.
