# Slide Brief Template

Documents the YAML schema used in `deck.md`: one optional deck header, then one YAML front-matter block per slide followed by optional body markdown. The host agent fills the slide template once per slide, copying the YAML block into `deck.md` between slide delimiters.

## Deck header

`deck.md` opens with one fenced `yaml` block before the first slide. Every key is optional, so a `deck.md` without a header stays valid; the renderer ignores keys it does not use.

```yaml
deck_mode: <enum>           # presented | keynote | briefing | reading. From intake; sets word budget and notes density (time-budget.md).
governing_idea: <string>    # the one-sentence governing idea from the audience brief.
sequencing: <enum>          # direct | indirect. The storyline shape chosen in Phase 3.
emotional_lever: <enum>     # hope | urgency | relief | adrenaline.
star_moment: <int>          # slide number of the S.T.A.R. moment, if any.
preset: <string>            # preset name, when one was known at design time.
```

## Copy rules

Write every `title`, `headline`, and on-screen phrase in `visual` to the active preset's `language.md` (the preset named in the header or in `.pgoell/presentations/config.md`; when that preset has no `language.md`, use the default preset's at `../../presets/default/language.md` relative to this skill). Keep on-screen words inside the deck mode's budget.

Never add a fact, figure, name, or arithmetic that is not in the user's material. That includes derived numbers: do not compute a percentage, total, or payback period the source does not state. When a slide needs a number the source lacks, say so in the title-only read-through (or ask) and write the claim without it; do not leave a placeholder that could render.

## Schema

The schema below defines the six top-level keys per slide. Four are required on every slide; two (`title`, `sources`) are optional. Sub-keys under `speaker_notes` are documented after the schema block.

```yaml
slide_type: <enum>          # required. One of: Title, Agenda, SectionDivider, Decision, Evidence, Transformation, Closing, Appendix.
title: <string>             # optional. Short topic label, two to five words, for layouts that pair a title with a subtitle; the headline then renders as the subtitle (the action title).
headline: <string>          # required. Full sentence with a verb and a claim, not a topic noun. Should match the storyboard headline verbatim. Renders on the layout's takeaway surface: the title, or the subtitle when a short title sits above it.
visual: <string>            # required. One line naming the slide's proof object (chart with insight, single number, highlighted bar, waterfall, table, process, 2x2, diagram, image, quote) and what it shows, or a pinned preset gallery layout by name. Every content slide carries a proof object; see slide-type-catalog.md.
speaker_notes:              # required. Five sub-keys, see below.
  transition: <string>
  claim: <string>
  evidence: <string>
  implication: <string>
  ask: <string>
sources:                    # optional. List of citations, omit entirely if no external data is shown.
  - <citation string>
  - <citation string>
```

### speaker_notes sub-keys

The speaker works through the sub-keys in order during the slide. Notes complement the slide; they never repeat its text. What the slide shows, the notes do not restate; they carry what the speaker adds (the why, the number behind the chart, the link to the next slide).

Density follows `deck_mode`:

- **`presented`, `keynote`, `briefing`: cues.** Each sub-key is a short phrase the speaker can glance at: a few words, the key number, the transition. Not a script.
- **`reading`: fuller prose.** One to three sentences per sub-key, since there may be no speaker and the notes stand in for one.

Size notes at about 130 spoken words a minute times the minutes planned for the slide (`time-budget.md`). The Decision slide's `ask` is the exception: when the ask is a motion or exact wording the speaker must read, write it out in full.

- **transition:** how the speaker arrives at this slide from the previous one. Names the prior claim and bridges to the current one.
- **claim:** the headline restated for the ear; the sentence the speaker actually says aloud as the slide opens.
- **evidence:** the supporting data point, quote, or benchmark the speaker cites to back the claim.
- **implication:** what the audience should now believe, decide, or do differently because of the evidence.
- **ask:** the explicit ask this slide makes of the audience (attention, agreement, a question to consider, a vote). For non-Decision slides this is usually an attention or comprehension ask; for the Decision slide it is the literal motion.

## When to omit a key

The schema has two optional top-level keys.

- **`title`:** omit when the layout carries a single heading surface (a Title slide's hero line, a SectionDivider's label, a quote layout). Include on content slides when the target preset's layouts pair a short title with a subtitle; the title names the topic, the headline carries the story.
- **`sources`:** omit entirely if the slide shows no external data, quotes, or benchmarks. A Title, Agenda, SectionDivider, or Closing slide typically has no sources. An Evidence slide almost always does.

## Worked example: Decision slide

The notes here are fuller than cues because the `ask` is a motion the chair needs word for word; the other sub-keys could be cues as well.

```yaml
slide_type: Decision
title: Our ask
headline: Approve one intake workflow now to cut onboarding cycle time 35 percent in H2
visual: Single-motion card with the exact motion text the chair will read, vote-tracker row beneath
speaker_notes:
  transition: We have walked through the diagnosis, the fix, the peer benchmark, and the payback. The remaining question is procedural.
  claim: I am asking the board to vote on a single motion that authorizes scope and budget for the unified intake workflow.
  evidence: The motion text on screen matches the language approved by counsel and references the 1.4M USD budget line detailed in the appendix.
  implication: A yes vote authorizes the PMO to begin implementation in the next sprint. A no vote preserves the four current BU intakes and the 11-week cycle time.
  ask: Madam Chair, I move that the board approve scope and budget for the unified intake workflow as presented, effective next sprint.
```

ASCII layout sketch:

```
+----------------------------------------------------+
|  DECISION                                          |
|                                                    |
|  MOTION:                                           |
|  +----------------------------------------------+  |
|  | The board approves scope and budget for the  |  |
|  | unified intake workflow as presented,        |  |
|  | effective next sprint.                       |  |
|  +----------------------------------------------+  |
|                                                    |
|  VOTE TRACKER:                                     |
|  CEO     [ ]  CFO     [ ]  COO     [ ]             |
|  Dir A   [ ]  Dir B   [ ]                          |
|                                                    |
+----------------------------------------------------+
```

## Worked example: Evidence slide

This deck is `presented`, so the notes are cues. The chart already shows the six quarters and the target line; the notes add the source and the consequence.

```yaml
slide_type: Evidence
title: Onboarding cycle time
headline: Onboarding cycle time has held above 10 weeks since Q3 2025
visual: Line chart, 6 quarterly data points from Q3 2024 to Q4 2025, current value of 11 weeks highlighted in red, target line of 7.2 weeks drawn in green
speaker_notes:
  transition: From the KPI to the trajectory it is on
  claim: Six quarters above 10 weeks; 11 today
  evidence: Ops dashboard, pulled Monday; 7.2 weeks is what the KPI needs
  implication: Structural gap; KPI misses on this path
  ask: Hold 11 weeks; later slides refer back to it
sources:
  - Internal Ops dashboard, pulled 2026-05-23
  - FY26 retention KPI memo (Board pack, Q4 2025)
```

ASCII layout sketch:

```
+----------------------------------------------------+
|  Onboarding cycle time has held above 10 weeks     |
|  since Q3 2025                                     |
|                                                    |
|  weeks                                             |
|   12 |              o---o---o (11.0)               |
|   11 |        o---o                                |
|   10 |  o---o                                      |
|    9 |                                             |
|    8 |                                             |
|    7 |==============================  target 7.2   |
|    6 |                                             |
|      +----+----+----+----+----+----                |
|       Q3   Q4   Q1   Q2   Q3   Q4                  |
|       2024 2024 2025 2025 2025 2025                |
|                                                    |
|  Source: Internal Ops dashboard, 2026-05-23        |
+----------------------------------------------------+
```
