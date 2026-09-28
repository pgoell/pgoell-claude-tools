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

## Fonts

| Family | Files                        | Source                                                                                                         | License                        | Size  |
| ------ | ---------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------ | ----- |
| Inter  | `inter/Inter-Variable.woff2` | npm `@fontsource-variable/inter@5.3.0`, `files/inter-latin-wght-normal.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 48 KB |

`inter/OFL.txt` is the license file from the same package. The file is unmodified.

## Gaps

- Not yet built from the catalog for this voice: comparison (StatSlide covers two values).
- ImageSlide has no bundled photograph; a deck must supply one.
- Light-scope versions of the slides are not rendered in the gallery; the tokens support them.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
