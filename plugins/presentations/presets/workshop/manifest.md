# Preset: workshop

## Who this serves

Training, facilitation, and mixed or low-vision audiences. Invitational "you" titles, large captions, and a hyperlegible body face. All copy in the example slides is fictional placeholder content for an invented retrospectives workshop.

## Sources

- Colors, type scale, fonts, layout coverage, and wording rules come from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md`, section "The Preset Specs", Preset E, plus "Layout catalog" and "Wording rules for `language.md`").
- Grounding cited by the report: Atkinson Hyperlegible for mixed audiences, the color-blind-safe Okabe-Ito palette reordered per scope for contrast, and a warm ground that sidesteps the "cream canvas with muted red" tell through a teal accent with a warm partner.
- Before and after title pairs in `language.md` adapt an example quoted in the report from Duarte, plus rewrites from this preset's own gallery story. The report notes that workshop copy conventions are thin beyond question and invitational titles.

## Coverage

- `colors.css`: layout tokens for the grammar (`--grid-cols`, `--grid-col`, `--grid-gutter`, `--panel-pad`, `--panel-gap`, `--r-xl`, `--r-2xl`); warm light scope and a deep green `.dark` scope with swapped inverse tokens; the chart group with `--chart-highlight`, `--chart-context`, `--chart-grid`, and five Okabe-Ito colors per scope; the type scale (72px titles, 44px body, 30px captions).
- `typography.css`: Fraunces for titles and Atkinson Hyperlegible Next for everything else, both vendored, plus `--font-display-settings` for the softened upright title cut.
- `guidelines.md`: voice, skeleton, and the layout grammar (grid, panels, density, signature moves, accent job, never list). `language.md`: the ten wording rules with the workshop tone line.
- `slides/`: built from this preset's layout grammar, not from the default layouts: TitleSlide, AgendaSlide, SectionDivider, ContentSlide, BarChartSlide, StatSlide, ProcessStepsSlide, ExerciseSlide, DiscussionSlide, RecapSlide, ClosingSlide. Each embeds a synced copy of the variable files and makes no network request.
- `assets/fonts/`: the vendored font files with their licenses.

## What this direction avoids

Warm paper with a teal accent, a soft serif for titles, and a hyperlegible sans; avoids the cream canvas with muted red, italic flourishes, and clip-art workshop slides.

## Decisions

- 2026-09 rebuild: the six base slides were rebuilt from the layout grammar in `guidelines.md` (12 x 96px columns, content in 40px-radius panels, ink time box, dashed writing space, real numbered steps, session map on dividers), and five signature slides were added. No slide keeps the default preset's composition.
- The time box is an ink pill on `--bg-inverse`, not the accent, so the accent keeps one job: where the room is or what it does next.
- The example story is one consistent session: 90 minutes on 30 April 2026 from 10:00 to 11:30 (agenda blocks 10 + 20 + 25 + 10 + 20 + 5), a 60-minute retro in five steps (5 + 15 + 20 + 15 + 5, the phases from Derby and Larsen, Agile Retrospectives, 2006), and the next session on 14 May. Survey figures (78, 55, 41, 22%; 6 and 12 issues) are invented placeholders.

- `--chart-4` (`#CC79A7`, 2.89:1 on the light paper) stays below 3:1 as the report specifies, so it needs a direct label on every mark.
- `--accent-partner` (`#B4531A`, 4.73:1) marks shapes on `--bg-subtle` only, never text there.
- Charts default to highlight mode, so `--chart-highlight` points at the teal accent, not at the Okabe-Ito blue in `--chart-1`.
- Fraunces ships as the Fontsource latin file with all four axes (weight, optical size, SOFT, WONK) so titles can set the softened upright cut; the weight-only file lacks the SOFT axis. Fraunces has no tabular figures, so every number sits in Atkinson.
- The type scale sits in `colors.css`, as the preset contract asks. The dark scope redeclares `--border-accent` and `--chart-highlight`.

## Fonts

| Family                     | Files                                                                | Source                                                                                                                                                   | License                        | Size   |
| -------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ------ |
| Fraunces                   | `fraunces/Fraunces-Variable.woff2`                                   | npm `@fontsource-variable/fraunces@5.3.0`, `files/fraunces-latin-full-normal.woff2`, fetched 2026-09-28 via jsDelivr                                     | OFL-1.1, no Reserved Font Name | 121 KB |
| Atkinson Hyperlegible Next | `atkinson-hyperlegible-next/AtkinsonHyperlegibleNext-Variable.woff2` | npm `@fontsource-variable/atkinson-hyperlegible-next@5.3.0`, `files/atkinson-hyperlegible-next-latin-wght-normal.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 34 KB  |

Each family directory carries its `OFL.txt`, copied from the same package. Files are unmodified.

## Gaps

- Still adapted from the default preset when needed: comparison, 2x2 matrix, timeline, diagram, quote, full-bleed image, capabilities. Rebuild them in this grammar (panels, 12-column splits) before shipping them here.
- Atkinson Hyperlegible Next has no peer-reviewed effect sizes; the choice rests on its design intent.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
