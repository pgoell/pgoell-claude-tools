# Preset: keynote

## Who this serves

Stage talks: conference keynotes, town halls, and talks in darkened rooms where the audience watches the speaker. One idea per slide, dark by default. All copy in the example slides is fictional placeholder content for an invented "Lumen" talk about small teams.

## Sources

- The layout grammar in `guidelines.md` draws on the layouts research notes of the same report (`research/layouts-reference-decks.md`, section SQ2: Apple keynote style, TEDx Speaker Guide, Presentation Zen, Takahashi and Lessig methods).
- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset B, plus "Layout catalog" and "Wording rules for `language.md`").
- Grounding cited by the report: Apple's one-idea slides, Presentation Zen empty space, the TEDx 42pt minimum, the Takahashi method, and halation guidance for light text on dark.
- Before and after title pairs in `language.md` adapt examples quoted in the report from Duarte and AECharts, plus rewrites from this preset's own gallery story.

## Coverage

- `colors.css`: a light scope for lit rooms and PDFs and a near-black `.dark` scope that every slide uses by default, with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, and two series colors per scope; the stage type scale (720px mega number, 320px hero number, 200px statement, 104px titles, 56px body); the thirds grid tokens (`--third-x`, `--third-y`, `--measure`); the image slot tokens (`--image-placeholder`, `--scrim`); the dark scope also sets body weight to 300.
- `typography.css`: Inter as the single family, vendored.
- `guidelines.md`, `language.md`: voice, skeleton, the layout grammar (thirds grid, positions by job, density, signature moves, what the preset never does), the image slot procedure, and the ten wording rules with the keynote tone line (seven words or fewer).
- `slides/`, all built from this preset's layout grammar, none adapted from default: TitleSlide, SectionDivider, ContentSlide (a build of three lines), BarChartSlide (three columns), StatSlide (before and after numbers), ClosingSlide, plus the signature slides StatementSlide, BigNumberSlide, ImageSlide, QuestionSlide, QuoteSlide. Every slide root carries `class="dark"`. Each embeds a synced copy of the variable files and makes no network request.
- `slides/`, library additions rebuilt from first-hand frames of stage talks (composition and reveal only; the references' gradients, 3D textures, cube transitions, and photos are not copied). Each is a build and ships every step as its own `<section>` with `data-build-step` and `data-build-steps`:
  - BaseAndComparedSlide: a scale figure at `--fs-hero` hanging from the left margin, then a compared pair built as a column on the right thirds line, one figure standing on each horizontal thirds line; after the Stripe Sessions 2026 opening keynote ($1.9T, then 34% and 2%).
  - ThirdCategorySlide: two known things in image slots in the outer thirds, two hairlines on the vertical thirds lines, and a middle third that changes six times (question mark, three criteria as a line build, the wrong answer dimmed, the answer in the accent); after Apple's January 2010 iPad event.
  - LineExitsFrameSlide: a quarterly line with no axis or gridlines whose 2025 segment turns to the accent inside a band and runs out through the top edge; after the Stripe Sessions 2026 "new businesses launching" chart.
  - HighlightRegionSlide: one undimmed image slot at 70% of the width, one accent outline per step, the caption naming the outlined region; after Dick Hardt's OSCON 2005 "Identity 2.0" driver's licence slide.
  - ReplaceBuildSlide: one part at a time dead center, each replacing the last, then the three in a row, then the name of the whole; after Apple's Macworld 2007 iPhone introduction.
  - SilhouetteCompareSlide: two device side profiles drawn from their thicknesses at the same scale, overlaid on one baseline, labels at the ends; after Apple's Macworld 2008 MacBook Air profile slide.
  - PositioningDotsSlide: two axes marked only by the four words at their ends, alternatives built in `--chart-context`, the answer last in the accent in the empty corner; after Apple's Macworld 2007 smart versus easy-to-use chart.
  - UnitGridSlide: 480 hollow squares, one per person-day, and nothing else; step 2 fills the 120 a team of four needs; after Tim Urban's TED 2016 grid of life weeks.
- `assets/fonts/`: the vendored font file with its license.

## What this direction avoids

Near-black stage slides with off-white Inter and one blue accent; avoids the purple-gradient deck and the cream-canvas serif look, and gets its display character from extreme size contrast rather than a trendy face.

## Decisions

- Inter is the most cited "AI deck" font. The report keeps it for its x-height (0.546) and tabular figures and counters the tell with size contrast; Manrope is the named alternative.
- The 48 KB Fontsource latin variable file ships, not the 877 KB full file: it has no opsz axis, so the display look comes from weight and tight tracking.
- The type scale sits in `colors.css`, as the preset contract asks. The report's dark body weight of 300 is set in the `.dark` scope.
- The keynote catalog has no content layout; ContentSlide is rebuilt as a build (one slide per line, earlier lines dimmed) because TEDx and Apple ask for no bullets. The deck engine has no in-slide build steps, so a build is a run of copies of the slide.
- Layout grammar, 2026-09-28 rebuild: every slide places its one element on the thirds grid or dead center, with no header or footer band, so the gallery differs from the other presets in structure, not only color. Centered title and closing lines follow Apple and the SlideSpeak "Keynote Minimal" reading; everything else stays left aligned on a thirds line, as the report asks.
- ImageSlide ships a painted placeholder instead of a stock photo (no photos are bundled). The placeholder is a CSS gradient stack with an inline SVG noise tile, declared as `--image-placeholder` so its colors live in `colors.css`; `data-image` or `--image` on the slot swaps in the real photo.
- StatSlide and BigNumberSlide split the number job: StatSlide pairs a before and an after value at `--fs-hero`; BigNumberSlide shows one value at `--fs-mega`.
- The accent colors a word only on StatementSlide (the phrase the sentence turns on), and only once, as `colors.css` allows.
- `--chart-highlight` (set to `--accent`) was added to the report's chart group; the dark scope redeclares it and `--border-accent`.
- Library additions, 2026-09-29: the new builds ship every step in one file as consecutive `<section>` elements, as `creating-presentations` describes builds, where ContentSlide shows only its last step. The fictional story continues: the Lumen launch log (40 launches, 17 of 20 by teams of four on date) gains 6 of 20 on date for teams of eight or more, and new fictional sources (the Lumen release log, 2021 to 2025, and hardware spec sheets for a card reader) carry the line and profile slides.
- BaseAndComparedSlide puts the accent on the base figure, as the reference sets it apart, and adds a source line the reference lacks. It is not StatSlide: three sizes, an asymmetric hero plus column split, an undimmed compared pair, and no title.
- ThirdCategorySlide uses image slots where the reference shows product photos, cuts the criteria from seven to three, and gives only the answer the accent (the reference is white throughout). The hairlines are structure on the thirds lines, not a decorative rule.
- LineExitsFrameSlide drops the reference's dotted gridlines and year axis (the grammar bans both) and keeps only the first value, the two end years, and the last value as labels, so the calm history band sets the scale. PositioningDotsSlide drops the reference's frame and axis lines for the same reason, and its five circles in three colors become three in `--chart-context` and one in the accent.
- HighlightRegionSlide outlines, never dims: neither reference uses a scrim. Its caption uses `--fs-body`, as ImageSlide does, rather than the caption size the shortlist named, because it is the only text on the slide.
- ReplaceBuildSlide replaces the reference's icons with words (the preset has no icon library) and its cube transitions with plain cuts; it uses no accent, since the repetition is the build.
- SilhouetteCompareSlide draws generic fictional card readers as clean SVG wedges from their data (`data-series` thicknesses and `data-length`), so the shapes stay at true relative scale.
- UnitGridSlide keeps the reference's lack of any text; as a full-canvas visual it is exempt from the 60% empty rule, like ImageSlide. The grid runs 32 by 15 rather than the reference's 90 by 52 so each unit stays visible from the back of a room; the accent step is an addition.

## Fonts

| Family | Files                        | Source                                                                                                         | License                        | Size  |
| ------ | ---------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------ | ----- |
| Inter  | `inter/Inter-Variable.woff2` | npm `@fontsource-variable/inter@5.3.0`, `files/inter-latin-wght-normal.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 48 KB |

`inter/OFL.txt` is the license file from the same package. The file is unmodified.

## Gaps

- Not yet built from the catalog for this voice: comparison (StatSlide covers two values).
- ImageSlide, ThirdCategorySlide, and HighlightRegionSlide have no bundled photograph; a deck must supply one, and HighlightRegionSlide's outlines must be moved onto the real photo's regions.
- Seen in the references but not built: a polarity flip across one-word slides (Hardt), the two-level sparkline (Duarte TEDx 2011), a full-slide treemap (McCandless; too many marks for this voice), and a poll then results sequence (Rosling; a run of QuestionSlide then StatSlide covers it). Lessig's word build, Gore's before and after glacier photos, and a map-scale overlay were not seen first-hand and are not built.
- Light-scope versions of the slides are not rendered in the gallery; the tokens support them.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
