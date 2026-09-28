# Preset: keynote

## Who this serves

Stage talks: conference keynotes, town halls, and talks in darkened rooms where the audience watches the speaker. One idea per slide, dark by default. All copy in the example slides is fictional placeholder content for an invented "Lumen" talk about small teams.

## Sources

- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset B, plus "Layout catalog" and "Wording rules for `language.md`").
- Grounding cited by the report: Apple's one-idea slides, Presentation Zen empty space, the TEDx 42pt minimum, the Takahashi method, and halation guidance for light text on dark.
- Before and after title pairs in `language.md` adapt examples quoted in the report from Duarte and AECharts, plus rewrites from this preset's own gallery story.

## Coverage

- `colors.css`: a light scope for lit rooms and PDFs and a near-black `.dark` scope that every slide uses by default, with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, and two series colors per scope; the stage type scale (104px titles, 56px body, 320px hero number); the dark scope also sets body weight to 300.
- `typography.css`: Inter as the single family, vendored.
- `guidelines.md`, `language.md`: voice, skeleton, and the ten wording rules with the keynote tone line (seven words or fewer).
- `slides/`: TitleSlide, SectionDivider, ContentSlide (the keynote form: three items of a few words), BarChartSlide (three bars), StatSlide (one number, no chart), ClosingSlide. Every slide root carries `class="dark"`. Each embeds a synced copy of the variable files and makes no network request.
- `assets/fonts/`: the vendored font file with its license.

## What this direction avoids

Near-black stage slides with off-white Inter and one blue accent; avoids the purple-gradient deck and the cream-canvas serif look, and gets its display character from extreme size contrast rather than a trendy face.

## Decisions

- Inter is the most cited "AI deck" font. The report keeps it for its x-height (0.546) and tabular figures and counters the tell with size contrast; Manrope is the named alternative.
- The 48 KB Fontsource latin variable file ships, not the 877 KB full file: it has no opsz axis, so the display look comes from weight and tight tracking.
- The type scale sits in `colors.css`, as the preset contract asks. The report's dark body weight of 300 is set in the `.dark` scope.
- The keynote catalog has no content layout; the ContentSlide here is the sparse form (a short title and three short items) so the gallery covers the structural set.
- `--chart-highlight` (set to `--accent`) was added to the report's chart group; the dark scope redeclares it and `--border-accent`.

## Fonts

| Family | Files                        | Source                                                                                                         | License                        | Size  |
| ------ | ---------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------ | ----- |
| Inter  | `inter/Inter-Variable.woff2` | npm `@fontsource-variable/inter@5.3.0`, `files/inter-latin-wght-normal.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 48 KB |

`inter/OFL.txt` is the license file from the same package. The file is unmodified.

## Gaps

- Not yet built from the catalog for this voice: statement, comparison, quote, and full-bleed image slides.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
