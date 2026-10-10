---
name: creating-presentations
description: Use when the user wants to build a multi-slide HTML presentation styled from a brand preset with a bundled default, or wants an existing deck reviewed, audited, or polished until it is genuinely done. Triggers on requests to create a deck, build slides, turn content into a presentation, or to audit, polish, or make a deck crisp. Includes a two-window presenter view for live sharing in Teams, Zoom, or Meet. For converting a finished HTML deck into editable PowerPoint, see the exporting-presentations-to-pptx skill.
---

# Creating Presentations

Multi-slide HTML decks styled from a brand preset, presented straight from the browser through a bundled deck-stage engine, and reviewed to done through a strict convergence loop. HTML is the working medium: fast to iterate, diffable, and exportable to native PowerPoint later without a redesign pass.

Building and perfecting are one lifecycle. A new deck flows top to bottom through the sections below: resolve the preset, choose a visual direction, compose, then check the render. The render check runs after every build without asking. A deck that already exists and only needs review enters directly at "Perfecting the deck". The perfecting loop is opt-in: it burns subagent tokens every round, so it starts only when the user asks for it or accepts the offer.

## Dependencies

The decks themselves are dependency-free: self-contained HTML that opens from `file://`. Tools enter only for presenting and perfecting; check for them when those branches start.

- A Chromium-based browser (Edge, Chrome, Arc) presents the deck: `BroadcastChannel` sync and the presenter's "Save to deck" (File System Access API) are Chromium-only. The same binary, headless, screenshots slides for the render check and the review loop: `chrome --headless --screenshot=slide.png --window-size=1920,1167 --hide-scrollbars <url>` (on Windows the preinstalled `msedge.exe` accepts the same flags). The window height is 1167, not 1080, because headless Chrome sizes the window and leaves a viewport about 993 px tall at 1080; 1167 gives a true 1920x1080 viewport.
- `uv` serves the deck over HTTP for the hard gates (`uv run python -m http.server 8123 --directory <deck-dir>`); webfonts and `BroadcastChannel` behave differently on `file://` origins.
- The default render check and the perfecting loop need subagent dispatch (the Workflow tool, or the Agent tool as fallback) for its judges and verifiers. Context isolation is what keeps the loop honest; without subagents, offer the user a single-pass review and say so, rather than simulating the loop inline.

## Resolve the preset first

Before writing any slide, resolve which preset styles the deck:

1. Prompt wins. An explicit preset name ("use the acme-corp preset") or a path to a preset directory settles it, and so does a `preset` key in the `deck.md` header.
2. Otherwise check `.pgoell/presentations/config.md` at the working repo root. Its `## Preset` section selects the active preset by `Name:` (resolved against local presets first, then bundled ones) or `Path:` (any directory that follows the preset contract). When the file names a preset, use it and say so.
3. Otherwise look for local presets in `.pgoell/presentations/presets/*/` at the working repo root. Exactly one: use it and say so. More than one: ask the user which to apply.
4. Otherwise choose among the bundled presets in `presets/` at the plugin root (`../../presets/` relative to this skill's directory) by the deck's use, state the choice and the reason in one line, and name the alternatives. `analytical` for decks read by or presented to decision makers, `keynote` for stage talks in dark rooms (and any `deck_mode: keynote`), `product` for launches and engineering all-hands, `editorial` for data stories and research readouts, `workshop` for training and mixed or low-vision audiences, `technical` for engineering deep dives, architecture reviews, design docs presented live, and incident reviews, and `default` when nothing points elsewhere. When the use is unclear and the user is present, ask. The table in `../../presets/README.md` under "Bundled presets" is the reference.
5. A brand the user names but no preset covers: offer the `extracting-presets` skill to build one from their brand material, and use a bundled preset only after they agree.

A preset contributes eight things: `colors.css` (inline into the deck head after the deck's own defaults so the preset values win the cascade), `typography.css` when present, `guidelines.md` when present (brand expression guidance: read it before composing, let it steer language, imagery, and layout choices, and hold finished slides against it as a filter), `language.md` (the positive style contract for copy: terminology, word usage, citations, and required legal language; apply it to every written surface from titles to speaker notes, and honor its required legal elements, which can dictate per-slide footer content and back-cover legal blocks; when the preset has none, use the default preset's `language.md` at `../../presets/default/language.md`), `assets/` (inline SVG directly as markup, base64-encode raster images), `icons/` when present (the brand icon library: grep its `index.tsv` by name, category, or keyword, then inline the SVG as markup and set its color through CSS `color`, following any icon rules in `guidelines.md`; icons come only from here, never drawn freehand), `assets/fonts/` when present (copy each family directory into the deck's own `assets/fonts/` so the `@font-face` URLs in `typography.css` resolve unchanged from the deck HTML; a single-file deck base64-encodes the font into the `src` instead, and a family with a Reserved Font Name, such as IBM Plex or Source Sans 3, is never subset), and `slides/` as the gallery of layouts to consult. The full preset contract lives in `../../presets/README.md`; read it before consuming preset files.

## Choose a visual direction

Before composing a new deck, choose its look: propose three or four directions drawn from the subject's industry, materials, and vernacular (background, accent with its job, type pairing, one motif, layout concept), always including the quiet default look; render one sample slide per direction side by side; let the user pick, or in an autonomous run compare two at a time with the order swapped; then lock the winner as `direction.md` and `direction.css` next to the deck. With a client preset active, only the motif and layout concept are open. The full procedure, including the palette-swap test and when to skip, is in `references/visual-direction.md`.

## The canvas

Author every slide on a 1920x1080 canvas (16:9). Layout grammar:

- Outer padding 80 to 120 px. The empty space is part of the brand.
- 12-column grid with 32 px gutters as a soft guide. A preset that declares its own grid as layout tokens in `colors.css` (`--grid-cols`, `--grid-col`, `--grid-gutter`, and zone tokens such as `--title-top` or `--body-top`) wins over this default; its `guidelines.md` documents the grid under `## Layout grammar`.
- One idea per slide. Three ideas means three slides.
- Type from the preset's scale tokens: body 40 px (never under 36), captions, chart labels, and table cells at least 28 px, footer and source line at least 24 px. At most three text sizes per slide, footer aside; a hero number or a workshop time box marked `data-role="hero"` is the one exception. Never shrink text to fit: split the slide, cut words, or move detail to the notes. Hard gate H7 measures this by role, so mark small text with `data-role="caption"`, `"label"`, `"legend"`, `"footer"`, or `"source"` when its class does not say what it is (a section tracker counts as footer when marked `data-role="footer"`); `references/hard-gates.md` lists every allowed value. These floors are starting points from the exporter's arithmetic (0.5 pt per px), not sourced numbers.
- Footer only where the preset needs one: a source line, a brand wordmark, or legal elements its `language.md` requires. Keep it lighter than the content, with no full-width accent rule and no slide counter. Structure slides (title, section divider, quote, closing) carry no footer and use the preset's dark scope, so the audience sees where the deck turns.
- The numbered visual rules (V1 to V13: two families, one accent with a stated job, same color same meaning, left-aligned body, lists of two to four, line length, change signals information, chart rules, a source line on every number) live in `references/deck-standards-default.md`. Read them before composing; the render check and judges cite them.

## Deck contract

Emit decks that honor this structure, so the stage engine, the presenter view, the review probes, and the PPTX exporter consume them without rework:

- Each slide is a `<section>` with a `data-screen-label` attribute carrying a short human-readable slide name (the presenter view displays it and the PPTX export uses it as the slide name). Slides are the direct element children of one `<deck-stage>` element; never place slides outside it.
- Slides are addressed by 1-based index on the URL hash (`#3`).
- Speaker notes live in a JSON island keyed by 1-based slide index. Notes are the presenter's voice, not filler: carry over what a `deck.md` source brief or the user provides, and otherwise leave a slide's entry out; the presenter view handles missing notes gracefully ("No notes for this slide"), while an invented note puts words in the presenter's mouth. When shaping notes you were given, make them complement the slide rather than repeat it. For presented and keynote decks use cues: short phrases, the key numbers, and a transition line to the next slide. For briefing and reading decks, full prose is fine. Size notes at about 130 spoken words a minute of the slide's time.

  ```html
  <script type="application/json" id="speaker-notes">
  { "1": "Open with the value prop. Twenty seconds." }
  </script>
  ```

- All styling flows through CSS custom properties declared in `:root` or in a preset variant scope such as `.dark`. Hardcoded colors in slide markup break preset swapping and the PPTX token lift.

## The stage engine

This skill bundles the deck-stage engine in its `assets/` directory: `deck-stage.js`, `presenter.js`, and `presenter.html`. Copy them unmodified next to the deck; they are brand-neutral and carry no preset styling. `deck-stage.js` defines the `<deck-stage>` web component: CSS-transform scaling of the authored canvas to any viewport, keyboard navigation (arrows, Space, Home/End, number keys), a resizable thumbnail rail with drag-to-reorder and skip (each thumbnail is a live clone of its slide, styled by the deck's own CSS), a print stylesheet that lays one slide per page so Print to PDF just works, and slide hiding via `visibility` so iframe and video state survives navigation. Tooling that measures geometry (the review probes, the PPTX exporter) sets the `noscale` attribute on `<deck-stage>` to read authored-canvas pixels.

Wire a deck like this:

```html
<style>deck-stage:not(:defined){visibility:hidden}</style>
<deck-stage>
  <section data-screen-label="01 Title">...</section>
  ...
</deck-stage>
<script src="deck-stage.js"></script>
<script src="presenter.js"></script>
```

## Composing the deck

When a `deck.md` from the `designing-presentations` skill exists, it is the source brief. Its header may carry `deck_mode` (`presented`, `keynote`, `briefing`, or `reading`; a missing header or key means `presented`), `governing_idea`, `sequencing`, `emotional_lever`, `star_moment`, and `preset`; deck mode sets the word budget, the notes format, and the title length (keynote titles are short claims with the full sentence in the notes). Its audience brief seeds the deck brief in the constitution. Its per-slide blocks name each slide's type, headline, visual, and speaker notes. Render the headline as written as the slide's dominant heading (`h1.action` in the gallery); a block's short `title` label, when a layout shows one, sits above it in a smaller size and never takes the dominant position. A visual brief that pins a gallery layout by name settles the layout choice. Without a `deck.md`, compose directly from the user's content.

**Copy.** Write every surface to the active `language.md` (the preset's, or the default preset's). Never add a fact, figure, name, quote, date, or calculation that is not in the source material or the user's input; when a claim needs a number the source lacks, write the claim with what the source does have and tell the user what is missing. After the build, hard gate H8 runs the copy lint in `references/copy-lint.md`; its long word lists stay there and out of the prompt.

**Layout.** Choose each slide's layout from its argument role and its proof object, the evidence that makes the claim believable. Then find gallery examples of that kind: resolve the role and proof object to tags with `../../presets/TAGS.md` and search `slides/index.tsv` in the active preset first, then across every preset (`grep -P '[\t,]benchmark[\t,]' ../../presets/*/slides/index.tsv`, and local presets when present). Open two or more matches, take the structure from the closest one, and borrow spacing and density from the others. Vary layout families across consecutive slides; repeat a layout only when the repeat tells the audience the content is parallel (three client cases in a row). Every bundled preset ships its own gallery of eleven layouts or more, built to its layout grammar (read `## Layout grammar` in the preset's `guidelines.md` before composing). The table maps roles to the default preset's base layouts and to the base layouts each voice preset adds; the library slides added since (eight more per preset, such as `analytical/GapToTargetSlide`, `keynote/ThirdCategorySlide`, `technical/IncidentTimelineSlide`) appear only in `slides/index.tsv`, so search the index rather than stopping at the table:

| Argument role or proof object                          | Default gallery                  | Voice preset galleries                                                                                                             |
| ------------------------------------------------------ | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Opening: deck title, subtitle, meta line               | TitleSlide                       | TitleSlide in every preset                                                                                                         |
| Answer first: summary whose points map to later titles | ExecSummarySlide                 | analytical ExecSummarySlide                                                                                                        |
| Route through a longer deck                            | AgendaSlide, SectionDivider      | workshop AgendaSlide (timed); SectionDivider in every preset                                                                       |
| Claim backed by two to four points                     | ContentSlide                     | ContentSlide in analytical, product, editorial, workshop; keynote ContentSlide (as a build); editorial ColumnsSlide                |
| One idea stated alone, or a question to the room       | none                             | keynote StatementSlide, QuestionSlide; workshop DiscussionSlide                                                                    |
| One number is the message                              | StatSlide                        | StatSlide in every preset but technical; keynote BigNumberSlide                                                                    |
| Several numbers read together                          | none                             | product MetricsRowSlide                                                                                                            |
| Trend, ranking, or comparison in data                  | ChartInsightSlide, BarChartSlide | BarChartSlide in every preset but technical; analytical ChartTakeawaySlide; editorial AnnotatedLineChartSlide, SmallMultiplesSlide |
| Latency or another measure against a threshold         | none                             | technical LatencyChartSlide                                                                                                        |
| How a total moves from A to B                          | WaterfallSlide                   | none                                                                                                                               |
| Many values the audience looks up                      | TableSlide                       | editorial TableSlide                                                                                                               |
| Options scored against criteria                        | none                             | analytical ScorecardSlide; technical TradeoffTableSlide                                                                            |
| A problem broken into its parts                        | none                             | analytical IssueTreeSlide                                                                                                          |
| Steps in order (five at most)                          | ProcessSlide, TimelineSlide      | analytical ProcessSlide (phased workplan); workshop ProcessStepsSlide; technical PipelineSlide                                     |
| Plan over time, or what shipped                        | TimelineSlide                    | product RoadmapSlide, ChangelogSlide                                                                                               |
| Options placed on two dimensions                       | MatrixSlide                      | none                                                                                                                               |
| Before and after, us and them                          | ComparisonSlide                  | product BeforeAfterSlide                                                                                                           |
| How parts of a system connect                          | DiagramSlide                     | technical ArchitectureSlide, DataFlowSlide                                                                                         |
| Calls between components in time order                 | none                             | technical SequenceSlide                                                                                                            |
| Code as evidence                                       | none                             | technical CodeSlide                                                                                                                |
| A decision record: context, decision, consequences     | none                             | technical DecisionSlide                                                                                                            |
| A photo or screenshot as evidence or context           | ImageOverlaySlide                | keynote ImageSlide; product ScreenshotSlide                                                                                        |
| The customer's own words                               | QuoteSlide                       | keynote QuoteSlide; editorial PullQuoteSlide                                                                                       |
| What the offer includes                                | CapabilitiesSlide                | none                                                                                                                               |
| An activity the room does, and what it takes away      | none                             | workshop ExerciseSlide, RecapSlide                                                                                                 |
| The decision, its consequence, next steps              | ClosingSlide                     | ClosingSlide in every preset                                                                                                       |

When the active preset lacks a layout for a role, build it from that preset's layout grammar: its grid tokens, zones, and compositions as its `guidelines.md` describes them. Take only the content structure (what goes on the slide) from the closest layout in another gallery, the default's included, never its composition. Agenda and section dividers earn their place in longer decks; a short deck goes without them. When no gallery layout fits, compose a new slide from the preset's variables and grammar, then offer it back into the preset's gallery as a contribution. That feedback loop is how the gallery grows.

**Builds.** A build reveals a list one line at a time, as the `keynote` preset does. It is a run of copies of one slide, each a full `<section>` with its own `data-screen-label`, adding one line and dimming the earlier ones. Mark each copy with `data-build-step="<n>"` (1-based) and `data-build-steps="<total>"`. The stage engine, the speaker notes, and the exporter treat every copy as its own slide.

**Image slots.** A gallery layout that needs a photo it cannot ship marks the slot with `data-placeholder="image"` and paints `--image-placeholder`. Before delivery, replace every slot with a real image from the user or the source and drop the attribute, or tell the user which slides still carry one. Never hand over a deck with a silent placeholder.

**Images, icons, and charts.** Every content slide carries a proof object; nothing on a slide is decoration. Use an image only as evidence or context (the site, the product, the people involved), never a stock cliché or a mood picture; full-bleed images are at least 1920x1080 and put text on a 40 to 60% dark overlay or a solid band. Icons come only from the preset's `icons/` library, and only where they help the audience find something; never draw an icon freehand or reach for a generic one (lightbulb, gear, rocket). Charts are rendered from data, with the values in the slide and carried in `data-*` attributes as the chart gallery layouts show, so the PPTX exporter can build native charts; follow the chart rules in V12 and put a source line on every quantitative slide. Chart colors come from the preset's chart tokens, never from hex values or the text accent: by default gray plus one, with the series the title names in `--chart-highlight` and every other series in `--chart-context`, gridlines in `--chart-grid`, labels placed next to the marks instead of a legend, and `font-variant-numeric: tabular-nums lining-nums` on chart labels and tables. Reach for `--chart-1` onward, in order, only when the categories themselves are the point, and split the chart rather than exceed the colors the preset declares. Accent-colored text uses `--accent-ink` when the preset declares one.

## Output layout

Multi-file is the shape for a deck that lives in a repo: `index.html`, the deck's own CSS file, the three engine files, and an `assets/` directory. Single-file is the shape for a deck that travels as one attachment (mail, Teams): inline the deck CSS, `deck-stage.js`, and `presenter.js` into the HTML, inline SVG as markup, and base64-encode raster images. Either shape opens from `file://` without a server. The presenter view needs the `presenter.html` sidecar next to the deck file, so a strictly single file has no presenter mode; when presenter mode matters for a traveling deck, ship the pair.

## Check the render

After every build, before handing the deck over, run the default render check from `references/review-loop.md`: hard gates H1 to H9 (`references/hard-gates.md` and `references/copy-lint.md`) plus one screenshot pass by one fresh subagent against the constitution's flaw taxonomy (occlusion, font sizing, alignment, spacing, contrast, misplaced decoration, leftover placeholder). Fix what it finds with the smallest change and check again, two fix rounds by default and three at most; then report what passed and what is still open, including any slide that still carries `data-placeholder="image"`. First renders usually have real defects, and a fresh look finds what the builder no longer sees. This check is not the perfecting loop: offer the loop afterwards for decks that must be flawless.

## Presenter mode

Open the deck in a Chromium browser (Edge, Chrome, Arc). From the deck window, `P` opens the presenter window (allow the popup once), `B` blacks out the audience screen. From the presenter window: `B` blackout, `T` resets the timer, `E` edits the current slide's notes (`Esc` finishes), `.` or `K` blacks out the presenter view itself. Arrow keys, Space, Home, End, and clicks move both windows.

Notes are editable live from the presenter: edits autosave to localStorage per deck and survive reloads, and "Save to deck" writes the updated JSON island back into the deck HTML via the File System Access API (Chromium only). While the presenter window is open, the deck window hides its thumbnail rail and overlay so the shared window shows clean slides.

Sync uses `BroadcastChannel`, no server required, and works across `file://` pages in Chromium (they share one storage origin). Never reach into a sibling window's DOM: `file://` documents are opaque origins to each other, which is why notes and state travel over the channel and `postMessage`.

To change a finished deck by hand, or to point at elements instead of describing them, see the `editing-presentations` skill.

Sharing in Teams, Zoom, or Meet: open the deck, press `P`, then pick **Share to Window** and select the deck window only. Never **Share screen**, or the presenter notes leak.

## Perfecting the deck

A strict reviewer that does not stop at "looks good". The loop dispatches fresh judge and verifier subagents every round, so it is token intensive; it runs only on the user's go-ahead. A request to review, audit, polish, or perfect the deck is that go-ahead. After building a deck and running the render check, offer the loop instead of starting it: name the cost (several subagents per round, typically a few rounds) and wait for a yes. The deck is done when fresh reviewers can no longer find anything that survives adversarial scrutiny against an explicit standard. Never ask "is the deck perfect?": a self-graded loop collapses into early self-approval, and a "be very strict" reviewer never terminates. Ask "did this round find anything new that survives verification?" and stop only when:

1. every hard gate passes, and
2. two consecutive review rounds produce zero verified findings at or above the severity threshold, and
3. the round cap (default 5) has not been hit. If it is hit, stop and report the remaining open findings honestly instead of looping forever.

Three rules keep the loop convergent rather than oscillating:

- **Judges cite the constitution, never taste.** A finding without a rule citation is not a finding.
- **Fresh judges every round.** A judge subagent is never reused and never told which round it is. The fixer (the main session) never judges; judges never fix.
- **The ledger ratchets.** Findings rejected by verification are recorded; an identical finding in a later round is auto-dismissed without re-judging. The finding space only shrinks.

The constitution is `deck-standards.md` next to the deck HTML. If it does not exist, copy the bundled default from `references/deck-standards-default.md` there, tell the user, and invite them to edit it; the copy, not the bundled file, is what judges receive. The active preset's `guidelines.md` and `language.md` join the constitution when present. Before round 1, fill the constitution's deck brief (audience, goal, time budget, constraints); ask the user if you cannot infer it. The loop edits the deck, so commit or stash first; one commit per round keeps every round diffable.

Each round, in a `.deck-review/` directory next to the deck:

1. **Measure.** Run hard gates H1 to H9 from `references/hard-gates.md` (clipped text, overlap, broken assets and fonts, console errors, banned characters, contrast, minimum type size, copy lint, layout geometry) and capture one full-size screenshot per slide. A hard-gate failure is a fix item by definition, no judging involved.
2. **Review.** Dispatch one fresh judge subagent per soft dimension (narrative, clarity, visual, delivery), each given the screenshots first, then the constitution (including the V rules and flaw taxonomy), the deck source, and the probe notes, nothing else. Judges answer one yes/no item per rule per slide and never score overall; when a fix must be compared with the version before it, use the pairwise prompt with the order swapped.
3. **Verify.** Every finding faces an adversarial verifier prompted to refute it. Refuted findings die into the ledger; blockers, and all findings in strict mode, get a three-verifier majority.
4. **Fix.** The main session applies the smallest change that resolves each confirmed finding, hard-gate failures first. Never batch a speculative redesign into a fix round.
5. **Repeat** from step 1 until the convergence rule terminates the loop.

Prompts, schemas, the ledger format, and a Workflow script template for one round live in `references/review-loop.md`; read it before dispatching judges. Severity runs blocker, major, minor, nit; the default threshold is minor (nits are reported but do not block convergence), and strict mode (the user says "strict" or "no nits") drops the threshold to nit with three-verifier majorities throughout.

Keep `report.md` in the run directory updated every round: findings raised, verified, rejected, auto-dismissed, fixed, plus hard-gate status and the final verdict with its evidence ("rounds 4 and 5 dry, all gates green"). Never claim the deck is done without the dry-round evidence.

## Caveats

- Decks that load webfonts or icons from CDNs render differently offline. Every bundled preset vendors its fonts under `assets/fonts/`; copy them with the deck as described above, and vendor any other webfont the same way, otherwise font fallbacks produce false overflow findings.
- Screenshot judges need vision via the Read tool on PNG files; capture screenshots to disk first, then pass paths.
