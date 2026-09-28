# Storyboard Template

Fill this in after the message architecture and before any slide briefs. The storyboard is the deck's table of contents at the headline level: every slide gets a sentence headline (not a topic noun), a slide_type drawn from the eight canonical types, a visual brief naming its proof object, and the one ask the speaker note must satisfy. If a slide's headline does not advance the pyramid, cut or merge it.

The storyboard is also the last cheap moment to change the deck. Slide briefs are 5-10x the effort per slide of a storyboard row; reordering, cutting, or adding a slide here costs minutes, doing it after slide briefs are written costs hours.

`storyboard.md` has five sections, in this order: competing storylines, choice record, title-only read-through (with assumptions), deck metadata, slide table.

## Competing storylines

A single draft is the model's most probable path, and that path follows the order of the source material. Draft two or three storylines instead, **titles only**, each a different shape:

- **Answer-first (direct):** the governing idea on slide 1, an optional exec summary, then one section per pyramid reason, then the ask. Fits an audience that agrees or is neutral.
- **Indirect:** start from facts the audience already accepts, meet the strongest objection with the evidence the brief names, then state the answer and the ask. Fits a skeptical or under-informed audience.
- **What is / what could be:** alternate the current state and the future state, pair by pair, ending on the stakes if they say no and the ask.

Always include the shape that matches the brief's `Sequencing` field. Build each candidate from the audience brief (strongest objection, evidence that overcomes it, stakes if no, emotional lever), not from the order of the source document. Each candidate is a numbered list of headlines, nothing else: no visuals, no notes.

## Choosing one

When the user is present, show the candidates side by side and let them pick (or merge).

In autonomous runs, compare two at a time and swap the order, since a judge tends to favor whichever it reads first:

1. Compare A then B, then B then A. For each order, answer one question: "Which storyline moves this audience (per the brief) to the CTA, meets the strongest objection before the ask, and would not fit an unrelated deck?"
2. If both orders pick the same candidate, it wins. If they disagree, pick the one whose shape matches the brief's `Sequencing` field.
3. With three candidates, the winner meets the third the same way.

Use a fresh subagent per comparison when subagents are available. Record the result in the choice record.

## Structure slides by length

Agenda and SectionDivider are opt-in. Defaults (tunable; the thresholds come from one practitioner source):

- Under 15 body slides: no Agenda, no SectionDivider.
- 15 to 19 body slides: an Agenda if the deck has three or more sections; no SectionDivider.
- 20 or more body slides with three or more sections: Agenda plus one SectionDivider per section.

A direct storyline may open with an **exec summary** at slide 2 at any length: `slide_type: Agenda`, its items are claims (not topics), one per body section, each a short form of that section's headline. The visual brief pins `ExecSummarySlide`. Phase 5 Check H verifies the mapping.

## S.T.A.R. moment

If the audience brief names a S.T.A.R. moment, give it its own slide and record the slide number in deck metadata. One per deck at most.

## Choice record

- **Candidates:** [letters and shapes]
- **Comparisons:** [each pair, each order, and the pick]
- **Chosen:** [letter and shape, with one sentence on why]
- **Source order:** [when a source document was the input: does the chosen order follow it front to back? If yes, name why that order is the argument (for example, chronology is the content)]

## Title-only read-through

Read only the chosen headlines, in order, and write three sentences a listener would use to retell the deck: situation, complication, resolution. Then one line: does the resolution sentence state the governing idea? Show this section, with the assumptions below, to the user before Phase 4.

**Assumptions:** list every `(assumed)` field from the audience brief, the decision and strongest objection first. Write "none" if none.

## Deck metadata

- **Deck title:** [working title, usually a compressed restatement of the governing idea]
- **Total slide count:** [count, must fall inside the recommended band from the audience brief]
- **Recommended band reference:** [the band recorded in the audience brief]
- **S.T.A.R. moment:** [slide number and what it shows, or "none"]

## Slide table

The eight canonical content-side slide types are: Title, Agenda, SectionDivider, Decision, Evidence, Transformation, Closing, Appendix. Pick one per row. Headlines are full sentences with a verb and a claim, written to the preset's `language.md`. The visual brief names the proof object (chart with insight, single number, highlighted bar, waterfall, table, process, 2x2, diagram, image, quote). The primary speaker-note ask names what the speaker adds that the slide does not show.

| Slide # | slide_type | Sentence headline   | Visual brief   | Primary speaker-note ask |
| ------- | ---------- | ------------------- | -------------- | ------------------------ |
| 1       | [type]     | [sentence headline] | [proof object] | [what the speaker adds]  |
| 2       | [type]     | [sentence headline] | [proof object] | [what the speaker adds]  |

## Worked example: 10-slide board intake-workflow approval briefing

The audience brief says the board is skeptical (sequencing: indirect), the strongest objection is "we tried this before", and the evidence that overcomes it is the PMO charter.

### Competing storylines

**A. Answer-first**

1. Approve one intake workflow now to cut onboarding cycle time 35 percent in H2
2. Intake is the bottleneck, the PMO can now fix it, and peers show the gain is real
3. Intake handoffs account for 6.4 of the 11 weeks
4. The PMO charter closes the authority gap that stalled both earlier attempts
5. Peer rollouts cut cycle time 38 to 41 percent inside one quarter
6. Approve scope and budget today so the PMO starts next sprint
7. A yes today protects the retention KPI; a deferral forfeits it

**B. Indirect**

1. Onboarding cycle time decides whether the FY26 retention KPI lands
2. Onboarding cycle time has held above 10 weeks since Q3 2025
3. Intake handoffs account for 6.4 of the 11 weeks
4. Both earlier attempts stalled because no one could enforce a shared SLA across BUs
5. The PMO charter closes that gap, so one PMO-owned intake can replace four
6. Peer rollouts cut cycle time 38 to 41 percent inside one quarter
7. The 1.4M USD investment recovers in 7 months from avoided churn
8. Approve scope and budget today so the PMO starts next sprint
9. A yes today protects the retention KPI; a deferral forfeits it

**C. What is / what could be**

1. Onboarding can drop from 11 weeks to 7.2 by the end of H2
2. Today 6.4 of the 11 weeks are handoffs between four BU intakes
3. Peers that moved to one intake cut cycle time 38 to 41 percent in a quarter
4. Today no one can enforce a shared SLA across the BUs
5. The PMO charter already gives that authority
6. Waiting costs roughly 180 customers in H2; approval starts the fix next sprint

### Choice record

- **Candidates:** A answer-first, B indirect, C what is / what could be.
- **Comparisons:** A then B: B. B then A: B. B then C: B. C then B: C. Orders disagree on B against C; the brief's sequencing is indirect, so B.
- **Chosen:** B. It meets the "we tried this before" objection (slides 4 and 5) before it asks a board that has said no twice.
- **Source order:** no source document; the material was several files.

### Title-only read-through

The retention KPI depends on onboarding, and onboarding has sat above 10 weeks for six quarters, mostly in handoffs between BUs. Earlier fixes stalled for lack of cross-BU authority, which the PMO charter now provides. So the board should approve one PMO-owned intake today, which peers show can cut cycle time 38 to 41 percent and which pays back in 7 months.

Resolution matches the governing idea: yes.

**Assumptions:** second objection ("why not standardize the SLA per BU"); emotional lever (urgency).

### Deck metadata

- **Deck title:** Approve one intake workflow now
- **Total slide count:** 10 (9 presentation + 1 appendix)
- **Recommended band reference:** 8 to 12 slides per time-budget.md for executive briefing at 20 minutes
- **S.T.A.R. moment:** slide 3, the 6.4 of 11 weeks spent in handoffs

### Slide table

| Slide # | slide_type     | Sentence headline                                                                  | Visual brief                                                                      | Primary speaker-note ask                                   |
| ------- | -------------- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| 1       | Title          | Onboarding cycle time decides whether the FY26 retention KPI lands                 | Title card, presenter name and date                                               | The KPI is tied to executive comp                          |
| 2       | Evidence       | Onboarding cycle time has held above 10 weeks since Q3 2025                        | Chart with insight: 6 quarterly points, 7.2-week target line, callout on 11 weeks | Six quarters, not a blip                                   |
| 3       | Evidence       | Intake handoffs account for 6.4 of the 11 weeks                                    | Single number: 6.4 of 11 weeks, with the value-stream map as a small stacked bar  | Handoffs, not provisioning, so the fix lives at intake     |
| 4       | Evidence       | Both earlier attempts stalled because no one could enforce a shared SLA across BUs | Table: two prior attempts, root cause from each retrospective                     | Name the objection before they do                          |
| 5       | Transformation | The PMO charter closes that gap, so one PMO-owned intake can replace four          | Process: four BU intakes merging into one PMO-owned intake, charter clause cited  | The authority gap is already closed                        |
| 6       | Evidence       | Peer rollouts cut cycle time 38 to 41 percent inside one quarter                   | Highlighted bar: 23 peer firms, median 38 percent, our 35 percent target marked   | 35 percent is below the peer median                        |
| 7       | Evidence       | The 1.4M USD investment recovers in 7 months from avoided churn                    | Waterfall: 1.4M USD cost, monthly avoided-churn value, payback at month 7         | A payback case, not a sunk cost                            |
| 8       | Decision       | Approve scope and budget today so the PMO starts next sprint                       | Motion card: exact motion text, vote row below                                    | Read the motion; say what yes authorizes and what no keeps |
| 9       | Closing        | A yes today protects the retention KPI; a deferral forfeits it                     | Single number: roughly 180 churn losses in H2 if deferred                         | End on the cost of waiting                                 |
| 10      | Appendix       | Budget, peer references, and prior-attempt retrospectives back the numbers above   | Table: three backup topics, each linked to the slide it supports                  | Only if asked in Q&A                                       |

No Agenda and no SectionDivider: 9 body slides is under the 15-slide default. The storyline is indirect, so there is no exec summary; the answer first appears on slide 5, once the strongest objection is met.
