# Audience Brief Template

Fill this in first, before any slide work. The audience brief constrains every other artifact (message architecture, storyboard, slide briefs) and prevents drift toward a deck that is technically correct but lands wrong for the room.

The brief is short on purpose. Resist the urge to write a stakeholder dossier; keep each field to the minimum that disciplines later decisions. If a field is hard to answer, that is signal: it usually means the deck does not yet have a clear audience, a clear governing idea, or a clear ask. Stop and resolve the gap before moving to message architecture.

## Sourced or assumed

Every field ends with a status marker:

- `(sourced: <where>)` when the user said it or it comes from the user's material, with a pointer ("user, intake answer 2", "board-pack.pdf p. 4").
- `(assumed)` when you inferred it.

In autonomous runs, derive each field from the user's material only. Do not answer from general knowledge of what such audiences usually want: that produces a deck for the average room. An assumed field stays as short and plain as the evidence allows, and never holds a number, name, or quote that is not in the material.

Two fields decide whether the deck can work: the **decision** (the CTA action) and the **strongest objection**. If either is assumed:

1. When a user is reachable, ask one question that covers both ("Who decides what, and what is their strongest reason to say no?").
2. Otherwise proceed, and list every assumed field at the top of the title-only read-through in `storyboard.md`, so the user sees the assumptions next to the storyline before anything is rendered.

## Audience

- **Role and seniority:** [role and seniority of the primary decision-makers in the room; if mixed, name the most senior block]
- **Prior knowledge of the topic:** [what they already know, what they have already heard pitched, and what is new to them; one to three sentences]
- **Expected agreement:** [agree | neutral | skeptical | under-informed; one clause on why]
- **Objections, strongest first:**
  1. [strongest objection, phrased as they would phrase it]
  2. [second objection, phrased as they would phrase it]
- **Evidence that overcomes the strongest objection:** [the specific fact, number, or precedent from the material that answers objection 1; if the material has none, write "none in material" and treat it as a gap]
- **Stakes if they say no:** [what the audience loses, in their terms, if they reject the ask; quantified where the material allows]

## Genre, length, and mode

- **Genre:** [one of: executive briefing | keynote | training | pitch | technical talk]
- **Duration:** [minutes; "n/a" for a reading deck]
- **Deck mode:** [presented | keynote | briefing | reading; sets the word budget and notes density, see `time-budget.md`]
- **Sequencing:** [direct | indirect. Direct (answer first) when expected agreement is agree or neutral; indirect (shared facts first, answer once the strongest objection is met) when skeptical or under-informed]
- **Recommended slide-count band:** [look up in `time-budget.md` from genre and duration; record the band here so the storyboard stays inside it]

## Governing idea

[One sentence, under 20 words, no jargon. A point of view plus what is at stake. This is the single claim the audience should remember if they forget everything else.]

A good governing idea passes three tests: (1) it is a complete sentence with a verb, (2) it is falsifiable (a critic could disagree with it), and (3) it answers the question the audience actually walked into the room with. "Intake reform" fails all three. "Approve one intake workflow now to cut onboarding cycle time 35 percent in H2" passes all three.

## Call to action

- **Actor:** [who has to act]
- **Action (the decision):** [what concrete decision or step is requested]
- **Timing:** [when, with a date or session boundary]
- **Consequence if delayed:** [what specifically gets worse if the actor defers; one sentence, quantified where possible]

The CTA is the only section of the brief that the closing slide echoes verbatim. If you cannot name the actor, the action is not yours to request. If the consequence-if-delayed is not quantified, the audience has no reason to act today rather than next quarter.

## Emotional target

- **Lever:** [one of: hope | urgency | relief | adrenaline. Pick one; the transformation arc and the Closing lean on it. The four-lever set is a tunable default from a single practitioner source, not a law.]
- **S.T.A.R. moment (optional):** [Something They'll Always Remember: one slide built to be retold (a striking number, a short customer quote, a before/after the room can see). Name the slide's content here; the storyboard marks which slide carries it. Leave blank rather than invent one the material does not support.]

## Worked example: board intake-workflow approval

### Audience

- **Role and seniority:** Board of directors: CEO, CFO, COO, two independent directors. CFO is the swing vote; COO already informally aligned. (sourced: user, intake answer 1)
- **Prior knowledge of the topic:** They have seen two prior intake-workflow proposals from BU-level teams in the last 18 months, both shelved as too narrow. They have not seen the cross-BU data. (sourced: 2024 retrospectives)
- **Expected agreement:** skeptical; two earlier proposals stalled. (sourced: user, intake answer 6)
- **Objections, strongest first:**
  1. "We tried this before with the BU-led proposals and it stalled. What is different this time?" (sourced: user, intake answer 1)
  2. "Why not let each BU keep its own intake and just standardize the SLA?" (assumed)
- **Evidence that overcomes the strongest objection:** The PMO charter, board-approved Q4 2025, grants the cross-BU authority both prior attempts lacked. (sourced: PMO charter)
- **Stakes if they say no:** The retention KPI tied to executive comp is missed; cycle time stays at 11 weeks through year-end. (sourced: FY26 retention KPI memo)

### Genre, length, and mode

- **Genre:** executive briefing (sourced: user)
- **Duration:** 20 minutes (15 presentation, 5 Q&A) (sourced: user)
- **Deck mode:** presented (sourced: user)
- **Sequencing:** indirect, because the board is skeptical (sourced: follows from expected agreement)
- **Recommended slide-count band:** 8 to 12 slides

### Governing idea

Approve one intake workflow now to cut onboarding cycle time 35 percent in H2. (sourced: user, intake answer 7)

### Call to action

- **Actor:** The board (formal vote) (sourced: user)
- **Action (the decision):** Approve scope and budget for the unified intake workflow, authorizing the PMO to begin implementation in the next sprint (sourced: user)
- **Timing:** Today, in this session, by formal vote (sourced: user)
- **Consequence if delayed:** Cycle time stays at 11 weeks through year-end, which projects to roughly 180 additional churn-attributable customer losses in H2. (sourced: Ops churn model, Q1 2026)

### Emotional target

- **Lever:** urgency (assumed)
- **S.T.A.R. moment:** 6.4 of the 11 weeks are spent passing work between teams. (sourced: value-stream map, Q1 2026)

In this example two fields are assumed. Neither is the decision or the strongest objection, so the run proceeds without a question and lists both at the top of the title-only read-through.
