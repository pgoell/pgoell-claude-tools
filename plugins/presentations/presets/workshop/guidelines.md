# Guidelines: workshop preset

## Voice

Warm and inviting. Talk to the room as "you", ask questions the group can answer, and give instructions people can follow without the facilitator repeating them.

## Use it for

Training sessions, facilitated workshops, onboarding, and talks for mixed or low-vision audiences.

## Skeleton

- Margins 120px at the sides, 96px at the top. Title top left at `--fs-h1` (72px), at most two lines. The full grid is under Layout grammar.
- Body at 44px and captions at 30px, above the floors, for people at the back and people with low vision.
- Footer: source line bottom left at `--fs-micro`, only when the slide shows numbers. No page numbers.
- Structure slides (title, section divider, closing) use the deep green `.dark` scope.
- Exercise slides state the task, the steps, the time, and the group size.

## Color

- The teal accent marks the one thing to do or notice. The warm partner marks shapes on `--bg-subtle` only, never text.
- Charts default to highlight mode: `--chart-highlight` (the accent) for the story series, `--chart-context` for the rest. The Okabe-Ito `--chart-1` to `--chart-5` serve charts where the categories are the point; `--chart-4` needs a direct label.

## Type

- Fraunces for titles only, upright and softened through `--font-display-settings`. Never set a number in Fraunces: it has no tabular figures.
- Atkinson Hyperlegible Next for body, labels, numbers, and tables, with tabular figures.
- No italic flourishes.

## Imagery

Photographs of real sessions, whiteboards, and artifacts the group makes. No clip art, no icon grids.

## Layout grammar

The slide talks to the participant. Every rule below serves a room that has to act on the slide without the facilitator repeating it. Grounding: facilitation practice (Duarte question titles, the report's invitational "you" tone), UK GDS and ONS accessible-slide advice (large type, left aligned, 50 words or fewer, no glare-white canvas), and Mayer's segmenting and signaling principles (one step at a time, a visible cue for where the room is).

### Grid

- 12 columns of 96px with 48px gutters inside 120px side margins (`--grid-col`, `--grid-gutter`, `--slide-pad-x`); 96px top margin. Panels snap to whole columns: the usual splits are 7 + 5 (content and writing space), 8 + 4 (evidence and a prompt), 4 + 4 + 4 (takeaways, prompts, session map), 5 + 2 + 5 (before, ratio, after).
- Title top left over at most 9 columns (1248px). Chips (time box, group size) sit top right on the title line.
- Content starts 48 to 64px under the title and fills to the bottom margin, or to 64px above the source line.

### Panels

- Every block of content sits in its own panel: `--bg-elev` with a 2px `--border` for content, `--bg-subtle` for prompts and context, `--r-2xl` (40px) corners, `--panel-pad` (48px) inside, `--panel-gap` (32px) between stacked panels. Nothing floats loose on the canvas except the title and the source line.
- Rows (agenda blocks, session map) use `--r-xl` (24px).

### Density

- About 20 to 50 words per slide, 2 to 4 items, one idea (ONS 50-word cap; Alley's tested slides averaged 21).
- At most 6 panels or rows per slide; a timed agenda holds 6 to 7 blocks, a process 4 to 6 steps.
- Whitespace is generous and deliberate: an empty panel is room for the group's answers, not a gap to fill.

### Signature moves

1. **The time box.** Activity slides carry an ink pill (`--bg-inverse`) with the minutes, "12 min", next to a group-size chip, top right or as its own large panel. The time box is never the accent.
2. **The writing space.** A dashed, empty panel (4px `--border-strong`, `--r-2xl`) holds a question to the room; the facilitator writes the answers on the flip chart or whiteboard. Content, agenda, and chart slides may end in one.
3. **Real numbered steps.** A real sequence gets 88px ink discs with the step number, or numbered stations on one connected path in SVG. Anything that is not a sequence gets no numbers.
4. **The session map.** Section dividers show the part number in a large accent disc and all parts along the bottom as done, now, and next.

### Accent job

The teal accent marks where the room is or what it does next: the current agenda block, the current part, the step practised today, the story bar in a chart, the one action on the recap, the commitment card on the closing slide. One accented element per slide.

### Titles

Questions or imperatives addressed to "you" on activity slides ("Map your last retro in silence", "What makes people speak up in your retros?"); claims addressed to "you" on evidence slides. Discussion slides set the one question at `--fs-display`; structure slides at `--fs-section` or `--fs-display`.

### Never

- Sharp corners, hairline rules, or content loose on the canvas.
- More than 4 instructions on an exercise, or an exercise without its time and group size.
- Numbers on items that are not a sequence; tracked caps, eyebrows, icon grids, clip art.
- Type under the floors to fit more: split into two slides.
- The accent on the time box, on decoration, or on more than one element.

## Layouts

Built in this preset: TitleSlide (session name, duration, what you leave with), AgendaSlide (timed vertical timeline with a parking lot), SectionDivider (part disc and session map), ContentSlide (points in panels plus a writing space), BarChartSlide (chart panel plus a question to the room), StatSlide (before and after panels with the ratio), ProcessStepsSlide (a real method as a connected path), ExerciseSlide (task, numbered steps, time box, group size), DiscussionSlide (one question and three prompts), RecapSlide (three takeaways and one action), ClosingSlide (the commitment card and the next session), LearningObjectivesSlide (questions beside what you can do, rows aligned across two panels), KnowledgeCheckSlide (a 2x2 of answers with a vote time box, then the reveal), GroundRulesSlide (norms as row panels beside what is off-topic today), WorkedExampleSlide (a fixed board on the left, the working built line by line on the right), ActivityAnatomySlide (a method in a dotted orbit of five slots), ScenarioSlide (a case that stays up beside a three-step protocol), HowWeWorkSlide (a legend of the deck's own signs and the start prompt), BreakSlide (the return time as the one accented element).

Adapt from the default preset when needed, in this grammar: comparison, 2x2 matrix, timeline, diagram, quote, full-bleed image.
