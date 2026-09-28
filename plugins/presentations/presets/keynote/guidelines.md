# Guidelines: keynote preset

## Voice

Spare and confident. One idea per slide, said in a few words, with the speaker carrying the argument. The slide is a backdrop, not a document.

## Use it for

Conference talks, stage keynotes, town halls in darkened rooms, and any talk where the audience watches the speaker rather than reads. Do not use it for decks that must be read alone; pick analytical or editorial instead.

## Skeleton

- Slides default to the `.dark` scope: every slide root carries `class="dark"`. Use the light scope only for lit rooms and PDF handouts.
- Margins 120px at the sides, 96px at the top and bottom. Place content on the thirds grid or dead center (see Layout grammar); nothing floats between grid lines.
- Titles at `--fs-h1` (104px) or larger, seven words or fewer, one to three lines; only the chart title in its left-third column drops to `--fs-h2` (88px).
- Body at 56px; at most three short lines, shown as a build, or none.
- No footer and no page numbers. A source line appears bottom left at `--fs-micro` only when the slide shows a number.

## Color

- The accent appears at most once per slide: the one bar, the one number, the one word.
- Charts: two to four bars, one chart per slide, `--chart-highlight` for the story bar and `--chart-context` for the rest, labels on the bars.
- Off-white text on near-black, never pure white on pure black.

## Type

- Inter throughout: 600 for titles, 300 for body on dark (set by the `.dark` scope), 400 on light.
- Big numbers use tabular figures and tight tracking. Get the display look from size and weight, not from extra faces.

## Imagery

Full-bleed photographs that are evidence or context for the point (the product, the place, the people), at least 1920x1080, with the title on a dark overlay or a solid band. No stock clichés.

## Layout grammar

Sources: Apple keynotes (one idea per slide, single-number slides such as "6 million"), TEDx Speaker Guide (one point per slide, no bullets, 42pt or larger, full-bleed photos, nothing in the far corners), Presentation Zen (empty space, rule-of-thirds crossing points, charts that restrain, reduce, emphasize), and the Takahashi and Lessig methods (one or two words in very large type, many slides). All figures are canvas pixels on 1920x1080.

**Grid.** Rule of thirds, not columns: vertical lines at x 640 and 1280 (`--third-x`), horizontal lines at y 360 and 720 (`--third-y`), inside a 120px side and 96px top and bottom margin (about the 5% broadcast-safe zone TEDx asks for). Every element either hangs from a thirds line, stands on one, or sits dead center. There is no header band, no footer band, and no gutter system, because a slide never holds two columns of text.

**Position.** Titles have no fixed slot; the slide's one element takes the position that fits its job:

| Job                          | Position                                                                      |
| ---------------------------- | ----------------------------------------------------------------------------- |
| Title line, closing sentence | Dead center, centered text                                                    |
| Statement                    | Full measure (`--measure`, 1680px), left aligned, vertically centered         |
| Big number                   | Centered, spanning about 80% of the width (`--fs-mega`)                       |
| Section divider              | Hangs from the left thirds line, stands on the lower thirds line              |
| Build of lines, quote        | Hangs from the left thirds line, vertically centered; the left third is empty |
| Question                     | Top left, first line near the upper thirds line; the lower right stays empty  |
| Chart                        | Title in the left third, the marks in the right two thirds                    |
| Before and after numbers     | The old number on the left thirds line, the new one on the right thirds line  |
| Image caption                | Bottom left on a 60% scrim (`--scrim`), never wider than two thirds           |

**Density.** One idea and one element per slide; a caption, a byline, or a source line may accompany it. At most about 15 words per slide, most slides under 7. At least 60% of the canvas stays empty on every slide except the image slide. Density comes from more slides, never from more per slide: a talk in this preset runs one slide per 20 to 40 seconds.

**Scale.** Four display sizes carry every slide: `--fs-mega` (720px) for the big number, `--fs-hero` (320px) for paired numbers, `--fs-statement` (200px) for title lines, statements, and dividers, `--fs-display` (168px) for questions and the closing. Supporting text is `--fs-body` (56px) or `--fs-caption` (36px); `--fs-micro` (28px) is for the source line only. Titles are Inter 600; quotes and supporting lines use the regular weight (300 on dark), so a quote reads as someone else's voice.

**Whitespace.** Empty space is the design, not leftover room. Do not fill an empty third with a logo, an icon, a rule, or a second point; if the slide looks empty, the idea is carrying it.

**Signature moves.**

1. The build: a list becomes the same slide repeated once per line, each copy adding one line in `--fg` and dimming the earlier ones to `--fg-subtle` (ContentSlide shows the last step; mark each copy with `data-build-step` and `data-build-steps`). No bullets, no markers.
2. The mega number: one number sized to span about 80% of the width, in the accent, with one line of context (BigNumberSlide).
3. Charts cut to two or three marks: bars as tall columns with the value on top and the name below, the story column in `--chart-highlight`, no axis, no gridlines, no legend (BarChartSlide).
4. Statement and question slides: one sentence at display size and nothing else; a statement may color the phrase it turns on, once (StatementSlide, QuestionSlide).

**Never.** Bullets or list markers, footers, page numbers, logos, agendas, executive summaries, tables, process or architecture diagrams, two charts or two ideas on a slide, legends, gridlines, axis lines, a source line on a slide without a number, text in the far corners, a centered paragraph, or text shrunk to fit. Content that needs a table or a diagram belongs in another preset or in a handout.

## Layouts

Gallery slides: TitleSlide (one huge line, byline), SectionDivider, ContentSlide (the build), StatementSlide, QuestionSlide, BigNumberSlide, StatSlide (before and after), BarChartSlide (three columns), QuoteSlide, ImageSlide, ClosingSlide (one sentence). Comparison is not built; use StatSlide for a two-value comparison and two slides for anything larger. Skip agendas, executive summaries, tables, process diagrams, and dense charts.

## Image slot

ImageSlide ships without a photograph. Its `.image-slot` element paints `--image-placeholder`, a dim stage-lit frame, until the slot names a real image: set `data-image="assets/<file>.jpg"` (a path relative to the deck, at least 1920x1080) and the slide's script sets `--image` on the slot, which covers the placeholder. The same works without the script by writing `style="--image: url('assets/<file>.jpg')"` on the slot. Keep the caption on the scrim, and describe the photo in the slot's `aria-label`. A finished deck never shows the placeholder: the slot carries `data-placeholder="image"` until an image is set, so a reviewer can grep for it. With no fitting photo, use a statement slide instead.
