# Slide Type Catalog

The eight content-side slide types used by this skill. Each type is a role in the argument, not a visual template. Rendering happens later in the `creating-presentations` skill; see the mapping at the bottom of this file.

A deck does not need every type, and types may repeat. A typical 12-slide deck uses 1 Title, 6 to 8 Decision or Evidence slides, 0 to 2 Transformations, 1 Closing, and any number of Appendix slides referenced from Q and A. Agenda and SectionDivider are opt-in by length (see their entries).

Every content slide (Decision, Evidence, Transformation) carries a proof object: the chart, number, table, process, 2x2, diagram, image, or quote that shows the headline is true. A slide with only bullets under its headline has not found its proof yet.

---

## Title

One-line purpose: orient the audience to the talk's topic and the speaker before the argument begins.

When to use it: always, as slide 1. Never use this layout again later in the deck.

ASCII layout sketch:

```
+----------------------------------------------------------+
|                                                          |
|                                                          |
|              Presentation Title (sentence)               |
|              Optional subtitle or framing                |
|                                                          |
|                                                          |
|              Speaker name, role, date                    |
|                                                          |
+----------------------------------------------------------+
```

Example sentence headline: "Migrating billing to event-sourced ledgers cuts month-end close from nine days to two."

Speaker-note pattern: introduce yourself in one sentence, name the audience's stake in the topic in one sentence, then advance to the next slide.

---

## Agenda

One-line purpose: preview the argument's structure so the audience can track progress through the deck.

When to use it: once, as slide 2, only on decks of 15 or more body slides with three or more sections (a tunable default). Below that the structure is easy to hold and the slide costs time. In a direct storyline, slide 2 may instead be an exec summary at any length: the items are claims, one per body section, each a short form of that section's headline, and the visual brief pins `ExecSummarySlide`.

ASCII layout sketch:

```
+----------------------------------------------------------+
|  Today's argument                                        |
|                                                          |
|    1. Section one (the problem)                          |
|    2. Section two (the evidence)                         |
|    3. Section three (the decision)                       |
|    4. Section four (what we are asking)                  |
|                                                          |
|                                                          |
+----------------------------------------------------------+
```

Example sentence headline: "We will walk through the problem, the evidence, the recommended decision, and the ask."

Speaker-note pattern: read each section name once, name the section that contains the ask so listeners know when the decision moment arrives, then advance.

---

## SectionDivider

One-line purpose: signal a transition between major sections of the argument so the audience can re-orient.

When to use it: only in decks of 20 or more body slides with three or more sections (a tunable default), one divider per section boundary. Under 15 slides, dividers add clutter.

ASCII layout sketch:

```
+----------------------------------------------------------+
|                                                          |
|                                                          |
|              Section 2 of 4                              |
|              The Evidence                                |
|                                                          |
|                                                          |
|              (optional one-sentence section summary)     |
|                                                          |
+----------------------------------------------------------+
```

Example sentence headline: "Section 2 of 4: the evidence behind the recommendation."

Speaker-note pattern: name what just ended in one short clause, name what comes next in one short clause, then advance without lingering (this slide is a breath, not a stop).

---

## Decision

One-line purpose: present a recommendation the audience must accept, reject, or amend, with the proof and the ask on the same slide.

When to use it: at every point in the argument where the audience is being asked to commit to something (a budget, a direction, a sign-off). Decision slides are the spine of a recommendation deck; if a deck contains zero Decision slides it is informational, not persuasive.

ASCII layout sketch:

```
+----------------------------------------------------------+
|  Sentence-takeaway headline stating the recommendation   |
|                                                          |
|  +--------------------+   +---------------------------+  |
|  |                    |   |  Ask: do X by date Y      |  |
|  |   single proof     |   |  Cost: $N, M weeks        |  |
|  |   visual (chart,   |   |  Benefit: outcome Z       |  |
|  |   diagram, photo)  |   |  Risk if delayed: ...     |  |
|  |                    |   |                           |  |
|  +--------------------+   +---------------------------+  |
|                                                          |
|  Sources: [1] internal report, [2] vendor benchmark      |
+----------------------------------------------------------+
```

Example sentence headline: "Approve the $400k Q3 spend on event-sourced billing to cut close time by 78%."

Speaker-note pattern: state the recommendation in one sentence, walk through the proof visual in one sentence, name the cost and benefit in one sentence each, then explicitly pause for the ask ("I am asking for sign-off on this today").

---

## Evidence

One-line purpose: deliver one quantitative or qualitative finding that supports a claim, with the finding visible at a glance.

When to use it: between Decision slides, to lay down the proof that justifies the next decision. Use one Evidence slide per finding; never stack multiple findings on one slide.

ASCII layout sketch:

```
+----------------------------------------------------------+
|  Sentence-takeaway headline stating the finding          |
|                                                          |
|  +----------------------------------------------------+  |
|  |                                                    |  |
|  |   full-width chart with ONE comparison or trend    |  |
|  |   highlighted (color, callout, annotation)         |  |
|  |                                                    |  |
|  |   - - - - - - - - - - - - - - - - - - - - - - -   |  |
|  |   reference line (target, baseline, SLO) if used   |  |
|  |                                                    |  |
|  +----------------------------------------------------+  |
|                                                          |
|  Sources: [1] data warehouse query, run 2026-05-12       |
+----------------------------------------------------------+
```

Example sentence headline: "Month-end close has lengthened from 5 to 9 days over the last six quarters."

Speaker-note pattern: read the headline as written, point to the highlighted comparison in the chart and name the magnitude, name the reference line if present, then connect to the next slide in one sentence.

---

## Transformation

One-line purpose: contrast a current state against a future state so the gap (and the path between) is visible on one slide.

When to use it: when the audience needs to internalize a before/after picture before being asked to commit (often immediately preceding a Decision slide). Also useful at the close of a section when the section's job was to redefine the problem.

ASCII layout sketch:

```
+----------------------------------------------------------+
|  Sentence headline stating the transformation            |
|                                                          |
|  +--------------------+        +----------------------+  |
|  |  CURRENT STATE     |        |  FUTURE STATE        |  |
|  |                    |        |                      |  |
|  |  - bullet a        |  ===>  |  - bullet a'         |  |
|  |  - bullet b        |        |  - bullet b'         |  |
|  |  - bullet c        |        |  - bullet c'         |  |
|  |                    |        |                      |  |
|  +--------------------+        +----------------------+  |
|                                                          |
|  What changes now: <one-line tagline>                    |
+----------------------------------------------------------+
```

Example sentence headline: "Moving from batch reconciliation to event sourcing flips close from a nine-day project to a two-day routine."

Speaker-note pattern: read the current-state column first as a single thought, read the future-state column as the contrast, name the one change that makes the difference (the arrow), then state the "what changes now" tagline aloud.

---

## Closing

One-line purpose: restate the deck's central recommendation and the immediate next step, so the audience leaves with one thing to do.

When to use it: always, as the last content slide (before any Appendix). Never use Closing as a Thank You slide; the closing slide is where the ask is reinforced, not where the deck politely ends.

ASCII layout sketch:

```
+----------------------------------------------------------+
|                                                          |
|  Sentence restating the central recommendation           |
|                                                          |
|                                                          |
|  Next step: <one concrete action, with date and owner>   |
|                                                          |
|                                                          |
|  Questions?                                              |
|                                                          |
+----------------------------------------------------------+
```

Example sentence headline: "Approve the $400k Q3 spend this week; engineering starts the migration on June 15."

Speaker-note pattern: restate the recommendation verbatim, name the next step and the date, name the owner of the next step by name, then open the floor for questions.

---

## Appendix

One-line purpose: hold supporting material that is not part of the live argument but may be needed in Q and A.

When to use it: for any content that would weaken the live deck's pace but that the audience may probe (detailed methodology, cost breakdown line items, alternative options that were rejected, raw data tables, FAQ). Place all Appendix slides after the Closing slide.

ASCII layout sketch:

```
+----------------------------------------------------------+
|  Appendix A: <topic>                                     |
|                                                          |
|  +----------------------------------------------------+  |
|  |                                                    |  |
|  |   detailed content: table, breakdown, methodology  |  |
|  |   note, rejected option, raw data                  |  |
|  |                                                    |  |
|  |                                                    |  |
|  +----------------------------------------------------+  |
|                                                          |
|  Referenced from: slide 7 (the cost claim)               |
+----------------------------------------------------------+
```

Example sentence headline: "Appendix A: full Q3 cost breakdown by engineering sub-team."

Speaker-note pattern: only spoken if jumped to from Q and A. Pattern: name the question being answered, walk through the supporting detail, return to the Closing slide.

---

## Rendering hand-off to the deck-building skill

The content-side type names above describe the role each slide plays in the argument. The deck-building skill works in a different vocabulary: the active preset's `slides/` gallery names rendering layouts. The recommended mapping below lets a host agent pass a content-side deck plan to the deck builder without re-deriving the layout from scratch each time. For content slides, the proof object named in the visual brief decides the layout more than the slide type does.

| Content-side type (this skill) | Recommended gallery layouts (deck builder)                                                  |
| ------------------------------ | ------------------------------------------------------------------------------------------- |
| Title                          | TitleSlide                                                                                  |
| Agenda                         | AgendaSlide; ExecSummarySlide when the items are claims                                     |
| SectionDivider                 | SectionDivider                                                                              |
| Decision                       | ContentSlide with a decision callout; ChartInsightSlide or StatSlide when the proof is data |
| Evidence                       | By proof object (table below)                                                               |
| Transformation                 | ComparisonSlide; ProcessSlide or MatrixSlide when the change is a flow or a 2x2             |
| Closing                        | ClosingSlide                                                                                |
| Appendix                       | TableSlide, or ContentSlide                                                                 |

| Proof object in the visual brief                | Recommended gallery layout |
| ----------------------------------------------- | -------------------------- |
| Chart with one insight called out               | ChartInsightSlide          |
| One number that carries the point               | StatSlide                  |
| Bar or column chart with one highlighted series | BarChartSlide              |
| A total built up or broken down step by step    | WaterfallSlide             |
| Rows and columns the audience compares          | TableSlide                 |
| Steps in order (five at most)                   | ProcessSlide               |
| Options placed on two axes                      | MatrixSlide                |
| Before and after, or two options side by side   | ComparisonSlide            |
| Dates or phases                                 | TimelineSlide              |
| Photo or screenshot as evidence                 | ImageOverlaySlide          |
| System, flow, or structure                      | DiagramSlide               |
| A customer or expert in their own words         | QuoteSlide                 |

The mapping is a recommendation, not a constraint. The deck builder chooses its own layout from the slide's argument role and proof object, and may pick differently when the visual brief calls for it. The two taxonomies sit at different levels of abstraction: this skill names the slide's role in the argument (content-role), while the deck builder names the layout that paints it (render-template). A one-to-one mapping is convenient but not load-bearing.

When a preset is known (the user names one, or exactly one is installed under `../../presets/` at the plugin root), its `slides/` gallery is the concrete form of the rendering vocabulary. List the gallery file names during storyboarding and let a visual brief pin one by name ("adapt chevron-process", "use WaterfallSlide"); a pinned gallery layout overrides the tables above. Users who work with their preset daily often know exactly which layout they want, and the pin carries that intent through to rendering unchanged.
