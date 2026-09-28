# Deck Standards

This file is the constitution for presentation review. Judges may only raise findings that cite a rule ID from this file; anything else is taste and gets rejected in verification. Hard gates (H rules) are measured by deterministic probes, never judged. Soft gates (S rules), visual rules (V rules), and flaw types (F items) are judged by fresh-context reviewers against screenshots, source, and the deck brief below.

Edit this file freely; it lives next to your deck as `deck-standards.md` and your edits override the bundled default. When the active preset ships `guidelines.md` or `language.md`, their rules join this file as part of the constitution: judges receive them alongside it, and a preset rule carries the same weight as an S rule. A preset without `language.md` falls back to the default preset's `language.md`.

## Severity scale

- **blocker**: the deck cannot be presented as is. Broken layout, factually wrong content, text unreadable at presentation distance.
- **major**: an audience member would notice and be distracted. Cramped slide, headline that states a topic instead of a takeaway, mismatched agenda.
- **minor**: polish. Inconsistent spacing, weak phrasing, redundant words.
- **nit**: defensible taste within the rules. Reported, but does not block convergence unless strict mode is on.

## Hard gates (measured)

Thresholds are tunable defaults; change them here and the probes in `hard-gates.md` follow.

- **H1 No clipped text.** No text element extends past the slide canvas. Slide content overflowing the canvas without clipping any text (decorative bleed, full-bleed panels) is not a failure; it is routed to the visual judge with the screenshot.
- **H2 No overlapping text.** No two text elements intersect by more than 4 canvas pixels in both axes.
- **H3 No broken assets.** Every image loads (`naturalWidth > 0`); no failed network requests for fonts, styles, or scripts; every declared font family has at least one loaded face. Partial weight failures (browser-synthesized bold from a loaded base weight, local-first font strategies) are routed to the visual judge as portability info, with a note that the deck renders differently on machines without the local font.
- **H4 No console errors.** The deck loads and navigates with a clean console. 404s for optional probe files on the allowlist below are exempt. Allowlist: `favicon.ico`.
- **H5 Typography lint.** Banned codepoints nowhere in rendered text: U+2014 em-dash, U+2013 en-dash, U+00B7 interpunct. Edit this list to your house style.
- **H6 Contrast floor.** Text elements longer than two characters (shorter ones are decorative markers) must reach 3:1 contrast against their effective background. Text under 24 canvas pixels that lands between 3:1 and 4.5:1 is routed to the visual judge as borderline, not auto-failed. Text over images or gradients is judged from the screenshot (S13).
- **H7 Minimum type size.** Rendered size by role on the 1920x1080 canvas: body at least 36 px, captions, chart labels, and table cells at least 28 px, footer and source line at least 24 px. These are starting points from the exporter's 0.5 pt per px arithmetic, not sourced numbers. Text never shrinks to fit: split the slide or cut words.
- **H8 Copy lint.** The hard-fail items of `copy-lint.md`: title over 15 words or two rendered lines, topic-label or count-only title, banned characters, and P0 tells (eyebrow label on most slides, italic or accent word in a title, a row of stat tiles, middle dot, P0 vocabulary). Its warnings go to the clarity judge.
- **H9 Layout geometry.** No colliding boxes, no content escaping its container, no content crammed against the canvas edge, no near-miss alignment, no touching blocks, no overloaded slide, per the thresholds in `hard-gates.md`. Balance and empty space go to the visual judge.

## Soft gates (judged)

### Narrative (dimension: narrative)

- **S1 One idea per slide.** A slide making two arguments is two slides.
- **S2 The deck has an arc.** The opening states a promise, each section advances it, the closing pays it off. A deck that is a list of facts fails S2.
- **S3 Agenda honesty.** If an agenda slide exists, the sections that follow match it in name, order, and count.
- **S4 Earned conclusions.** Any claim on a closing or summary slide must have appeared with support earlier in the deck.

### Clarity (dimension: clarity)

- **S5 Headlines carry the takeaway.** Each slide's dominant heading states what the audience should conclude, not the topic ("Migration cut costs 40%", not "Cost analysis"). A short topic label may sit above it in a smaller size; a topic label in the dominant position fails, even when a smaller subtitle carries the claim.
- **S6 Every element earns its place.** No filler text, decorative bullets restating the headline, or data shown but never used.
- **S7 Audience-fit language.** Jargon, acronyms, and assumed context match the audience named in the deck brief.
- **S8 Scannable in seconds.** A slide's point lands within roughly five seconds of looking at the screenshot. Walls of text fail S8. Word budgets per deck mode: presented and keynote about 20, briefing up to 50, reading 75 to 200.
- **S17 No invented facts.** Every number, name, date, and quote on a slide or in the notes appears in the source material or the user's input. A figure computed from source numbers says so in the source line.

### Visual (dimension: visual)

- **S9 Alignment discipline.** Like elements sit on a consistent grid across slides; edges that almost align are findings.
- **S10 One focal point.** Each slide has a clear visual hierarchy; if everything is bold, nothing is.
- **S11 Consistency of like elements.** Repeated element types (section dividers, stat callouts, footers, captions) look identical across slides in size, color, and position.
- **S12 Whitespace is part of the design.** Margins and breathing room are consistent; a slide noticeably denser than its neighbors is a finding against it, not against them.
- **S13 Text over imagery stays readable.** Where H6 cannot measure (images, gradients), readability is judged from the screenshot.

### Delivery (dimension: delivery)

- **S14 Speaker notes match and complement their slides.** A note describes the slide it is attached to and adds what the slide leaves out; a note that reads the slide text back, describes a different slide, or contradicts it is a finding. Presented and keynote decks use cue notes (short phrases, the key numbers, a transition line); briefing and reading decks may use full prose. Notes fit the time budget at about 130 spoken words a minute. Absent notes are a finding only when the deck brief requires notes. Notes are the presenter's voice: neither judges nor the fixer ever draft notes to satisfy this rule, and an empty notes entry is a valid state.
- **S15 Time budget.** Slide count and per-slide density fit the time budget in the deck brief (rule of thumb: one to two minutes per content slide).
- **S16 Presentable openings and closings.** The first and last slides work as static screens (audience waiting, Q&A) without the presenter talking. The closing slide ends crisply: it names the decision or next step and its consequence, not "Thank you" or "Questions?" alone.

## Visual rules (dimension: visual)

Most real decks break these rules, and people do not find them by instinct, which is why they are written down. Cite them like S rules.

- **V1 Two type families at most.** One for headings and one for body, or one family for both. A monospace face appears only for code.
- **V2 One accent with a stated job.** The accent color marks one thing (the data point that matters, the recommended option, the current step); everything else is the neutral ramp. The job is written in the deck's direction (see `visual-direction.md`).
- **V3 Same color, same meaning.** A color that means "our option" on one slide never means "risk" on another.
- **V4 Left-aligned body.** Body text, lists, and captions are left-aligned. Centering is for single short lines on structure slides.
- **V5 Short lists.** Two to four items, each at most two lines. Five points are two slides or a table.
- **V6 No underline and no all-caps runs.** Underline is for links; all caps only for a label of a word or two. Emphasis comes from position, size, or the accent, not from bold scattered through body copy.
- **V7 Readable line length.** Body lines run 45 to 80 characters; wider text gets a narrower column.
- **V8 Visual change signals information change.** A new layout, background, or color means new content (a new section, a shift from problem to answer). The same kind of content keeps the same look; parallel slides may repeat a layout on purpose.
- **V9 Structure slides look different.** Title, section divider, quote, and closing slides are visibly distinct from content slides (dark scope, no footer), so the audience sees where the deck turns.
- **V10 Proof object on every content slide.** Each content slide carries evidence for its claim: a chart, table, diagram, image as evidence, or one number. No decorative images, stock clichés, or generic icons (lightbulb, gear, rocket). Images are evidence or context only, at least 1920x1080 when full bleed, with a 40 to 60% dark overlay or a solid band behind any text on them. Icons come only from the preset's `icons/` library, never drawn freehand.
- **V11 Footer only where it earns its place.** A footer appears when the preset needs it (legal line, brand wordmark, source line); it is lighter than the content, and no full-width accent rule sits above it. Structure slides carry no footer.
- **V12 Charts show one message.** Charts are rendered from data (the slide carries its values, charts carry their data in `data-*` attributes), never drawn as loose shapes. Bars start at zero; no 3D, no donuts, pies only for two or three parts of a whole; direct labels instead of legends; light or no gridlines; one highlighted series in `--chart-highlight`, the rest in `--chart-context`, with colors read only from the preset's chart tokens; at most four highlighted units per chart; the chart's takeaway is the slide title or an insight callout pointing at the data.
- **V13 Every number has a source.** Every quantitative slide carries a source line (at least 24 px) naming where the numbers come from, with the date.

## Flaw taxonomy

The default render check (and the visual judge) looks for these defects on each screenshot. Each is a yes/no question per slide; a "yes" is a finding citing the F item and the slide.

- **F1 Occlusion.** Something covers or cuts off content: text under an image, a shape over a label, text cropped by its box.
- **F2 Font sizing.** Text too small to read at presentation distance, or sizes that do not match their role (a caption larger than the body, two body sizes on one slide).
- **F3 Alignment.** Edges that should line up do not; a column, caption, or label sits a few pixels off its neighbors.
- **F4 Spacing.** Uneven gaps between like elements, content crammed against an edge or another block, or one region crowded while another is empty.
- **F5 Contrast.** Text or a key chart mark that is hard to tell from its background.
- **F6 Misplaced decoration.** A rule, dot, shape, or icon that no longer fits its content (an underline sized for one line under a two-line title, a marker next to nothing).
- **F7 Leftover placeholder.** Template text, lorem ipsum, "Acme", sample numbers, or empty frames that the deck's content never replaced.

## Deck brief

Fill this in per deck before round 1. Judges receive it as part of the constitution.

- **Audience**:
- **Goal** (what the audience should think or do afterwards):
- **Deck mode** (presented, keynote, briefing, or reading; from `deck.md` when present, otherwise presented):
- **Time budget**:
- **Tone**:
- **Constraints** (brand, mandatory slides, things that must not change):
