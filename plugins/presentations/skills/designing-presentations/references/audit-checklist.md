# Phase 5 Heuristic Audit Checklist

This audit runs inline in the main session before the critic personas dispatch in Phase 5. Checks A to E are form checks: each states what to look for, how to look for it (grep pattern, YAML parse rule), and which slide types are exempt. Checks F to K are written-output checks: each one writes its working into `audit-report.md` (a retelling, a table, a sequence) before it judges. The written output is the point; a check that only answers "pass" is self-grading, and same-model self-grading is weak.

Every violation is recorded in `audit-report.md` under `### Heuristic findings`, one numbered item per violation. The host agent then fixes each violation in place or surfaces it to the user when the fix needs judgement. Only after the heuristic audit settles does the host agent dispatch the three critic personas (see `critic-prompts.md`).

## Check A: Headline is a sentence, not a topic noun

What: every slide's `headline` value must read as a complete sentence stating the slide's takeaway. A headline that is a noun phrase ("Q1 Results") or a topic label ("Onboarding cycle time") fails this check. The headline should answer "so what?" not "what topic?". This rule is sometimes called the assertion-evidence model in presentation-design literature; the headline asserts, the body provides evidence. The optional `title` key is a short topic label by design and is never judged by this check; the takeaway obligation sits on `headline` regardless of which surface (title or subtitle) renders it.

How to check: this is a heuristic, not a pure regex. The host agent reads each headline and flags it when any of the following is true.

- The headline contains no verb (no main verb, no copula, no auxiliary).
- The headline contains no clear subject.
- The headline ends in a bare noun phrase with no predicate.
- The headline reads as a section title or topic header (common patterns: `<Noun> Results`, `<Noun> Overview`, `<Metric> by <Dimension>`, `<Year> Update`).

Helpful starting grep to surface candidates for review:

```
grep -nE '^\s*headline:\s*"[A-Z][a-zA-Z ]+"\s*$' deck.md
```

That regex catches short, capitalised, punctuation-free headlines, the population most likely to be topic nouns. The host agent still reads each candidate in context before deciding.

Examples of fail and pass for the same slide topic:

- Fail: `headline: "Onboarding cycle time"` (topic noun).
- Fail: `headline: "Q1 onboarding"` (topic noun).
- Pass: `headline: "Onboarding cycle time has doubled since Q3 2024"` (subject, verb, predicate, takeaway).
- Pass: `headline: "Our onboarding pipeline is the binding constraint on Q2 revenue"` (subject, verb, predicate, takeaway).

Exempt slide types: `SectionDivider` (its headline is a section label by design), `Appendix` (its headline is a topic pointer for reference).

In a `keynote` deck the headline may be a short claim ("Close takes nine days"); it still needs a subject and a verb. Check A tests form only: a headline can pass it and still be generic. Check G tests specificity.

## Check B: Evidence slides have a non-empty sources field

What: every slide with `slide_type: Evidence` must have a `sources` field that is non-empty and that records, at minimum, the source name, the date or year, and the scope or sample size of the evidence. A bare URL with no date or scope fails this check.

How to check: parse `deck.md` as YAML-with-markdown-bodies. For every slide block where `slide_type == "Evidence"`:

1. Assert `sources` exists and is non-empty.
2. Assert the `sources` text contains a four-digit year between 2000 and the current year, OR an explicit date in `YYYY-MM` or `YYYY-MM-DD` form.
3. Assert the `sources` text mentions at least one scope marker: `n=`, `sample`, `respondents`, `customers`, `users`, `accounts`, `tickets`, `incidents`, `period`, `Q[1-4]`, or a date range.

Quick grep to surface candidates missing a year:

```
awk '/^slide_type:\s*Evidence/,/^---$/' deck.md | grep -A1 '^sources:' | grep -vE '\b(19|20)[0-9]{2}\b'
```

Exempt: none. Evidence slides without sourced evidence fail by definition.

## Check C: Decision slides have a specific ask

What: every slide with `slide_type: Decision` must have a `speaker_notes.ask` field containing four elements: actor (who decides), action (what they decide), timing (by when), and consequence-if-delayed (what happens if they do not). A vague "we should consider..." or "leadership alignment needed" fails this check.

How to check: parse `deck.md` as YAML. For every slide block where `slide_type == "Decision"`, read `speaker_notes.ask` and scan for the four elements.

- Actor: look for a named role, team, or person (`CFO`, `Steering committee`, `Pascal`, `Platform team`). Pronouns ("we", "they") fail unless preceded by a clarifying noun in the same field.
- Action: look for a decision verb (`approve`, `fund`, `sign off`, `green-light`, `commit`, `prioritise`, `de-prioritise`, `reassign`).
- Timing: look for a temporal anchor (`by end of Q3`, `before 2026-06-30`, `at the next steering meeting`, `within two weeks`).
- Consequence-if-delayed: look for a conditional consequence (`otherwise`, `if not`, `delays beyond`, `slips by`, `risks`, `blocks`).

Flag the slide if any of the four elements is missing or ambiguous.

Examples of fail and pass for a Decision slide ask:

- Fail: `ask: "We should align on the onboarding investment."` (no actor named beyond "we", no specific action, no timing, no consequence).
- Fail: `ask: "CFO to approve the onboarding budget."` (actor + action, but no timing, no consequence).
- Pass: `ask: "CFO to approve the EUR 180k onboarding budget at the 2026-06-12 steering meeting; further delay slips the Q3 hiring plan by one quarter and forces us to defer the EMEA expansion."` (actor, action, timing, consequence-if-delayed).

Exempt: none. Decision slides without a specific ask fail by definition.

## Check D: Chart-visual slides state a single comparison

What: when a slide's `visual` brief mentions a chart, plot, graph, bar, line, scatter, or similar visualisation, the brief text must state exactly one comparison the chart makes. Multi-comparison briefs ("show revenue, cost, and headcount over time, split by region") fail this check; the chart should be split into separate slides or simplified.

How to check: two passes.

1. Keyword pass: grep the visual briefs for chart-related terms.
   ```
   grep -nE 'visual:.*(chart|plot|graph|bar|line|scatter|histogram|pie|funnel|waterfall|sparkline)' deck.md
   ```
2. Comparison pass: for each match, scan the visual brief for comparison markers: `vs`, `versus`, `before/after`, `trend`, `over time`, `between`, `compared to`, `relative to`, `year-over-year`, `month-over-month`. Count the distinct comparisons asserted. If the count is not exactly one, flag the slide.

Examples:

- Fail: `visual: "Stacked bar chart of revenue, cost, and headcount by quarter, split by region, with target overlay."` (three measures, two dimensions, plus a target; at least four comparisons).
- Pass: `visual: "Bar chart of onboarding cycle time by quarter, 2024-Q3 through 2026-Q1, single series."` (one comparison: trend over time).
- Pass: `visual: "Before/after bar chart of cycle time, two bars only."` (one comparison: before vs after).

Exempt: `Appendix` (appendix charts may be reference material with multiple comparisons by design).

## Check E: Slide count is within the recommended band

What: the total slide count in `deck.md` must fall within the band recommended by `time-budget.md` for the genre and duration captured in `audience-brief.md`. A 10-minute conference talk with 35 slides fails; so does a 60-minute training session with 8 slides.

How to check:

1. Count `Slide` blocks in `deck.md` (one block per slide).
   ```
   grep -cE '^---\s*$' deck.md
   ```
   Adjust the divider pattern to match the deck's actual block boundary.
2. Read `genre` and `duration_minutes` from `audience-brief.md`.
3. Look up the recommended band for that genre/duration pair in `time-budget.md`.
4. Compare. If the count is outside the band, flag a violation.

Exempt slide types from the count: `Appendix` slides are counted and reported separately, since they do not consume live talk time. A `reading` deck has no talk time, so Check E does not apply to it.

User override: if the user explicitly requested an out-of-band slide count (recorded earlier in the session, ideally referenced in `audience-brief.md` or surfaced by the host agent), the audit-report records the override under a `### User overrides` section instead of flagging it as a violation. The override note must name the requested count and the recommended band so a later reviewer sees both.

## Check F: Title-only read-through (written)

What: read only the headlines, in order, and write the three sentences a listener would use to retell the deck: situation, complication, resolution. Compare them with the governing idea and the message architecture.

Write under `### Storyline read-through` in `audit-report.md`:

1. The three sentences.
2. **Match:** does sentence 3 state the governing idea's claim? Yes, or the difference in one line.
3. **Gaps:** any pyramid reason, or the strongest objection, that no headline carries.
4. **Repeats:** any two headlines that make the same claim.

Flag a violation for a mismatch, each gap, and each repeat.

## Check G: Specificity test (written)

What: a sentence headline can still be empty ("The company is growing revenue and shrinking costs" fits any annual review). Test the governing idea and every headline for two things: does it name something specific from the user's material (a number, an actor, or a comparison), and would it fit an unrelated deck on the same topic?

Write under `### Specificity` a table, one row per headline plus one for the governing idea:

```
| Slide | Specific element from the material | Would also fit |
| ----- | ---------------------------------- | -------------- |
| GI    | 35 percent, H2 (audience brief)    | none           |
| 02    | 11 weeks, since Q3 2025 (Ops dashboard) | none      |
| 05    | none                               | any process-improvement deck |
```

Flag a row when column 2 is "none" or column 3 names a deck. Flag as CRITICAL any number, name, or comparison in a headline that cannot be traced to the user's material; that is fabrication, not a specificity pass.

Exempt: `SectionDivider`, `Appendix`.

## Check H: Exec summary maps to body titles (written)

Applies when the deck has an exec summary (an Agenda slide whose items are claims, or a visual that pins `ExecSummarySlide`).

Write under `### Exec summary mapping` one line per exec-summary item: the item, then the body slide whose headline makes the same claim. Then list any body section that no item covers.

Flag an item with no matching slide, a body section with no item, and any pair where the item and the headline make different claims.

## Check I: Recommendation position (written)

What: a recommendation buried late loses the room. Write under `### Recommendation position`: the sequencing from the audience brief, the slide where the governing idea's claim first appears, and the slide carrying the CTA.

- **Direct:** the claim must appear on slide 1 or 2.
- **Indirect:** the claim must appear no earlier than the slide that meets the strongest objection, and before the Closing.

Flag a violation otherwise. In both shapes, a claim that first appears on the Closing is buried.

## Check J: Document order (written)

Applies only when a source document was the input. Models build decks in source order almost every time; human authors reorder often (one study measured 1.2 percent non-linear against 38.6 percent for human decks).

Write under `### Document order` the source section each body slide draws from, in slide order (for example `02: s1, 03: s4, 04: s2, 05: s3`). Then state whether the sequence runs front to back.

Flag MAJOR when it runs front to back, unless the storyboard's choice record says why source order is the argument order (for example, chronology is the content).

## Check K: Copy lint (by reference)

Run the copy lint (`presentations:creating-presentations`, `references/copy-lint.md`) over the text each slide will show on screen: `title`, `headline`, and any on-screen words named in `visual`. Pass `deck_mode` from the deck header so the lint applies the right word budget. The lint's lists live in that file only; do not restate them here or in `deck.md`.

Record the lint's hard-fail items as violations and its warnings as a separate `### Copy lint warnings` list. If the lint file is not installed, note "copy lint skipped: file not found" and continue.

## Violation report format

Each heuristic violation is recorded as a numbered item in the `### Heuristic findings` section of `audit-report.md`. The format is:

```
### Heuristic findings

1. Check A violation, Slide 04: headline reads as topic noun ("Cycle time"). Suggested fix: rewrite as sentence-takeaway, e.g. "Onboarding cycle time has doubled since Q3 2024".
2. Check C violation, Slide 09: speaker_notes.ask missing timing element. Suggested fix: add a temporal anchor, e.g. "by end of Q3" or "at the next steering meeting".
3. Check E violation, deck-level: 35 slides exceeds the 18-22 band recommended for a 20-minute conference talk. Suggested fix: cut to the 18-22 band, or move detail slides to Appendix.
4. Check G violation, Slide 05: headline "Our process is ready to scale" names nothing from the material and fits any process deck. Suggested fix: name the actor and comparison the material gives, e.g. "One PMO-owned intake replaces the four BU intakes".

### User overrides

1. Slide count: user requested 35 slides for a 20-minute talk (recommended band: 18-22). Override accepted at user direction.
```

If a form check (A to E) finds no violations, omit its line entirely; do not write "Check A: no violations". The absence of an item is the signal that the check passed. The written sections from Checks F to K stay in the report even when they find nothing, because the written output is what a reviewer checks.
