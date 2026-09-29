# Slide tags

Every example slide in a preset's `slides/` carries tags in that directory's `index.tsv`, one row per slide file. The tags come from the closed vocabulary below, so an agent can find the right layout across all presets with one grep instead of opening every file.

## index.tsv

Tab-separated, with a header row:

```
file	role	move	form	mode	sequence	summary
```

- `file`: the slide file name in the same directory.
- `role`, `mode`, `sequence`: exactly one value each.
- `move`: one or two values; `form`: one to three values. Several values are joined by commas with no spaces.
- `summary`: one plain sentence, at most 15 words, saying what the slide shows. Write it so a grep for an everyday word finds it ("Agenda", "Waterfall", "before and after").

Add or change a row whenever a slide is added, renamed, removed, or changes what it shows. A preset without an `index.tsv` still works; its slides simply do not show up in tag searches.

## Searching

Resolve the words of a request to values first, through the synonym columns below, longest phrase first ("positioning map" resolves to `two-axis` before "map" resolves to `map`). Then match whole values in their column, never prefixes or substrings. Fall back to the `summary` column for anything the vocabulary does not name.

```bash
# every agenda slide, in every bundled preset
grep -P '\tagenda\t' plugins/presentations/presets/*/slides/index.tsv
# every slide that benchmarks against a target, any form
awk -F'\t' '$3 ~ /(^|,)benchmark(,|$)/' plugins/presentations/presets/*/slides/index.tsv
# a waterfall, whatever the summary calls it
grep -iP 'part-chart|waterfall|bridge' plugins/presentations/presets/*/slides/index.tsv
```

Local presets under `.pgoell/presentations/presets/` follow the same format; include them in the glob when they exist.

## Values

Values are kebab-case and closed: do not invent a new value for one slide. When no value fits, pick the nearest and let the summary carry the detail. Grow the vocabulary only when several slides need the same missing value, and then update this file and every affected row together.

## Facet 1: role (position in the deck; one per slide). 8 values.

| Value         | Definition                                                                            | Synonyms                                                                                  |
| ------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `cover`       | Opening slide that names the deck                                                     | title, title-slide, front-page, opener                                                    |
| `agenda`      | Lists the parts or aims of the session before they start                              | overview, contents, table-of-contents, outline, talk-map, session-map, objectives         |
| `divider`     | Marks the move from one part to the next, including a pause                           | section, section-header, chapter, segue, break, pause                                     |
| `summary`     | States the conclusions of the deck or a part in one place, before or after the detail | exec-summary, executive-summary, key-findings, tl-dr, abstract, recap, takeaways, wrap-up |
| `body`        | Carries one claim and its evidence inside a part                                      | content, main                                                                             |
| `closing`     | Ends the deck: the last message, contact, or held Q&A                                 | end, thanks, contact, q-and-a, final                                                      |
| `appendix`    | Backup detail kept for reading or questions, not presented                            | backup, annex, reference-pages                                                            |
| `facilitator` | Not for projection: prep, notes, setup                                                | prep, presenter-only, do-not-present                                                      |

## Facet 2: move (what the slide does in the argument; one or two). 12 values.

| Value       | Definition (and boundary)                                                                                                                                     | Synonyms                                                                                                                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `frame`     | States the problem, opportunity, context, or scope the deck addresses, including how big it is. Not `explain` (frame says why it matters, not how it works).  | problem, pain, status-quo, challenge, context, background, why-now, scope, opportunity, market-size, tam                 |
| `explain`   | Shows what something is or how it works: a term, a method, steps, or a mechanism. Not `diagnose` (no fault is being located).                                 | definition, glossary, anatomy, how-it-works, method, workflow, mechanism, walkthrough                                    |
| `compare`   | Sets two or more items or states side by side on equal terms, or places items relative to each other, with no fixed reference. Not `benchmark`.               | versus, vs, contrast, before-after, a-b, pros-cons, then-now, landscape                                                  |
| `benchmark` | Measures one named subject against a fixed reference: peers or their average, a rank, a target, a threshold, or a plan. Not `compare` (there is a reference). | peer-comparison, ranking, league-table, top-n, vs-target, vs-plan, gap-to-target, threshold, sla, slo, promise-vs-actual |
| `trend`     | Shows how a measure changes over time, past or projected.                                                                                                     | over-time, growth, trajectory, forecast, projection, scenario                                                            |
| `decompose` | Splits a whole, or a change in it, into its parts.                                                                                                            | part-to-whole, breakdown, drill-down, mix, split, composition, contribution                                              |
| `prove`     | Shows credibility from outside the analysis: results achieved, adoption, customers, voices, credentials. Not `benchmark` (no reference is set).               | traction, social-proof, testimonial, credentials, case-study, track-record, reference-customers                          |
| `diagnose`  | Locates a cause or reads what went wrong.                                                                                                                     | root-cause, incident, debug, failure-analysis, postmortem                                                                |
| `evaluate`  | Judges options, or the robustness of a result, against stated criteria. Not `recommend` (it scores; it need not decide).                                      | options, trade-off, evaluation, scorecard, verdict, sensitivity, prioritisation, criteria                                |
| `recommend` | States what should be done or concluded, and what this audience must decide or give.                                                                          | recommendation, proposal, thesis, so-what, implication, the-ask, decision-required, call-to-action, funding-ask          |
| `plan`      | Says what happens next: who does what by when, or when the room resumes.                                                                                      | next-steps, workplan, action-plan, rollout, owners-and-dates, commitments, guidance                                      |
| `engage`    | Asks the audience to do something now: work, answer, vote, reflect, or give feedback.                                                                         | exercise, task, activity, breakout, role-play, quiz, knowledge-check, poll, vote, reflection, feedback, retro            |

## Facet 3: form (what is on the slide; one to three). 18 values.

| Value        | Definition                                                                                                          | Synonyms                                                                                                                                  |
| ------------ | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `statement`  | One sentence, phrase, or word as the whole slide                                                                    | main-point, big-idea, headline, one-word, takahashi                                                                                       |
| `big-number` | One figure dominates                                                                                                | stat, big-fact, hero-number, kpi                                                                                                          |
| `number-set` | Two or more figures in a row, column, or grid                                                                       | metrics-row, kpi-grid, number-row, dashboard, box-scores, bento                                                                           |
| `text-list`  | Short parallel text items: points, findings, names with roles, or wordmarks                                         | bullets, list, points, findings-list, team, people, logo-wall, customer-logos                                                             |
| `quote`      | Quoted words with attribution                                                                                       | pull-quote, quotation, epigraph                                                                                                           |
| `image`      | A photo, screenshot, or UI frame carries the slide                                                                  | photo, picture, screenshot, full-bleed, device-frame, mockup, ui-frame                                                                    |
| `table`      | Rows and columns of text, numbers, or marks such as Harvey balls or heat shading                                    | grid-table, reference-table, comparison-table, heatmap, harvey-balls                                                                      |
| `two-axis`   | Items placed by two values or two qualities                                                                         | scatter, bubble-chart, xy-plot, 2x2, quadrant, positioning-map, perceptual-map, matrix                                                    |
| `bar-chart`  | Values per category on one value axis, as bars, columns, lollipops, or dots                                         | column-chart, ranked-bars, grouped-bars, histogram, lollipop, dot-plot, dumbbell                                                          |
| `line-chart` | Lines or curves over a continuous axis                                                                              | curve, time-series, slope-chart, sparkline, fan-chart                                                                                     |
| `part-chart` | Bars, areas, or boxes split into parts, including bridges and shrinking areas that show nested subsets of one whole | stacked-bar, stacked-area, marimekko, mekko, waterfall, bridge, walk, 100-percent-bar, flame-graph                                        |
| `unit-chart` | One mark per unit, so the count can be seen                                                                         | isotype, icon-array, unit-grid, pictogram, dot-tally                                                                                      |
| `map`        | Geographic shapes carry data                                                                                        | choropleth, world-map, geo                                                                                                                |
| `timeline`   | Events, phases, or releases placed on a time axis                                                                   | milestones, gantt, lollipop-timeline, roadmap, changelog                                                                                  |
| `flow`       | Steps in order along one direction                                                                                  | process-flow, chevrons, funnel, pipeline, steps                                                                                           |
| `diagram`    | Nodes and connectors showing structure: architecture, states, hierarchy, network                                    | architecture, architecture-diagram, state-machine, sequence-diagram, tree, issue-tree, driver-tree, metric-tree, org-chart, hub-and-spoke |
| `code`       | Source code, commands, or command output in monospace                                                               | snippet, listing, terminal, cli, shell-output, log, diff                                                                                  |
| `canvas`     | Empty or partly filled structure for the room to work on                                                            | writing-space, workspace, template, sentence-frame, sticky-board                                                                          |

## Facet 4: mode (how the slide is consumed; one). 3 values.

| Value           | Definition                                      | Synonyms                                                   |
| --------------- | ----------------------------------------------- | ---------------------------------------------------------- |
| `presented`     | Relies on a speaker; little text                | keynote, stage, live, talk                                 |
| `read`          | Must work alone; complete sentences and sources | slidedoc, pre-read, leave-behind, briefing, readout, dense |
| `participatory` | The audience acts on it                         | interactive, facilitation, hands-on                        |

## Facet 5: sequence (does it stand alone; one). 3 values.

| Value    | Definition                                                                                                                     | Synonyms                                               |
| -------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ |
| `single` | Complete on its own                                                                                                            | standalone, static                                     |
| `build`  | Same frame across several steps, one change per step                                                                           | reveal, progressive, animation, word-by-word, layering |
| `pair`   | One of two related slides, shown back to back or at two points in the deck (a file with two sections that is not a step build) | slide-pair, rescale-pair, companion, repeat            |

The preset is not a tag: the directory already says it.
