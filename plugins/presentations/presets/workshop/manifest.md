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
- `slides/`, reference-deck additions of 2026-09-28 (composition and technique only; text and data continue this preset's retro story):
  - LearningObjectivesSlide: questions the session answers beside what you can do by the end, rows aligned across the two panels, the objective practised next in the accent; after the Carpentries Instructor Training episode overview (Questions and Objectives).
  - KnowledgeCheckSlide: a two-step build, a 2x2 of answer panels with a vote time box, then the reveal with the right answer in the accent and each wrong answer naming the misconception it shows; after the Carpentries diagnostic multiple-choice question.
  - GroundRulesSlide: five norms as row panels beside a prompt panel of what is off-topic today; after re:Work Bias Busting @ Work slides 12 and 13.
  - WorkedExampleSlide: a four-step build, a fixed board of notes and vote dots on the left and the working growing on the right, earlier lines dimmed and the current line in the accent; after MIT 6.S191 Lecture 1 slides 21 to 24.
  - ActivityAnatomySlide: a method in the middle of a dotted orbit with five slots (invitation, space and materials, who takes part, group size, steps and time), the invitation in the accent; after the Liberating Structures 1-2-4-All constellation slide.
  - ScenarioSlide: a case paragraph that stays up while groups talk, with its turn at the foot, beside a three-step protocol and the report-back time; after re:Work Bias Busting @ Work slides 15 and 16.
  - HowWeWorkSlide: a legend that teaches the deck's own signs with the real tokens (time box, sticky note, vote dots, writing space), two habits, and the start prompt in the accent; after the Remote Brand Sprint template slide 4.
  - BreakSlide: the return time as the one large accented element in the dark scope, with one line on what comes next; after the d.school Starter Kit "Refresh yourself!" slide.
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
- Builds (KnowledgeCheckSlide, WorkedExampleSlide) follow the keynote preset's mechanism: one full `<section>` per step, each with its own `data-screen-label`, `data-build-step`, and `data-build-steps`. The title stays fixed across steps.
- Reference-deck additions, contract conflicts resolved: numbers stay out of Fraunces titles, so the knowledge check says "filled the board" rather than a count; the synthesis gave ScenarioSlide an 8 + 4 split, rebuilt as 7 + 5 so the protocol fits at body size and the slide reads differently from ExerciseSlide (a case to discuss, not steps to follow); the worked example is a vote count, not an equation, which keeps each step to one line at body size; ActivityAnatomySlide places its slots on the grid columns with absolute canvas coordinates and marks only the invitation, not a dot per slot; BreakSlide's hero time uses proportional figures, since a single number has nothing to align. The vote-dot count (4 + 5 + 2 + 1 = 12 notes, 6 x 3 = 18 dots, 8 + 5 + 3 + 2 = 18) and the report-back time (11:20, inside the 11:05 to 11:25 block) are internal to the invented story.

## Fonts

| Family                     | Files                                                                | Source                                                                                                                                                   | License                        | Size   |
| -------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ------ |
| Fraunces                   | `fraunces/Fraunces-Variable.woff2`                                   | npm `@fontsource-variable/fraunces@5.3.0`, `files/fraunces-latin-full-normal.woff2`, fetched 2026-09-28 via jsDelivr                                     | OFL-1.1, no Reserved Font Name | 121 KB |
| Atkinson Hyperlegible Next | `atkinson-hyperlegible-next/AtkinsonHyperlegibleNext-Variable.woff2` | npm `@fontsource-variable/atkinson-hyperlegible-next@5.3.0`, `files/atkinson-hyperlegible-next-latin-wght-normal.woff2`, fetched 2026-09-28 via jsDelivr | OFL-1.1, no Reserved Font Name | 34 KB  |

Each family directory carries its `OFL.txt`, copied from the same package. Files are unmodified.

## Gaps

- Still adapted from the default preset when needed: comparison, 2x2 matrix, timeline, diagram, quote, full-bleed image, capabilities. Rebuild them in this grammar (panels, 12-column splits) before shipping them here.
- Reference-deck alternates not yet built: role play, sentence frames, example output, spectrum sliders, feedback cards, group rounds (1, 2, 4, all as growing clusters), and a facilitator prep slide.
- The builds ship as one file per build; the render check covered each step by hiding the others, not through the deck engine.
- Atkinson Hyperlegible Next has no peer-reviewed effect sizes; the choice rests on its design intent.
- No wordmark or `icons/` library: the preset serves a context, not a brand.
