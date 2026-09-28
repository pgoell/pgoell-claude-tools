# Message Architecture Template

Fill this in after the audience brief and before the storyboard. The message architecture turns the governing idea into a defensible argument shape (SCQA opener, answer-first pyramid, transformation arc, operational CTA) that every slide later traces back to. If the architecture is weak, no amount of slide polish will save the deck.

The message architecture is the committed argument. Phase 5 judges every critic finding against it, so a change to the governing idea, the reasons, or the CTA happens here, on purpose, not as a side effect of a critique.

The pyramid is the logic, not the slide order. It states the answer first because that makes the logic checkable; the storyboard (Phase 3) decides the order the audience meets it in, direct or indirect.

Evidence comes from the user's material only. If a reason has no evidence in the material, write "none in material" under it; do not supply a plausible number.

## SCQA opener

One-sentence subfields. The opener earns the audience's attention by stating a shared Situation, naming the Complication that disturbs it, posing the Question that the complication forces, and previewing the Answer the deck will defend.

- **Situation:** [one sentence of stable, shared context the audience already accepts]
- **Complication:** [one sentence naming what has changed or what is at risk in that situation]
- **Question:** [one sentence: the question the complication forces the audience to answer]
- **Answer:** [one sentence: the governing idea, restated as the direct answer to the question above]

## Answer-first pyramid

State the governing idea first, then group 2 to 4 MECE reasons under it. Each reason is a sentence-conclusion (a claim that could be true or false), not a topic noun (which cannot be argued with). Evidence sits under each reason as concrete data points, customer quotes, benchmarks, or prior commitments.

- **Governing idea (restated from audience brief):** [one sentence, under 20 words, no jargon]
- **Reason 1:** [sentence-conclusion]
  - Evidence: [data point, source, year]
  - Evidence: [data point, source, year]
- **Reason 2:** [sentence-conclusion]
  - Evidence: [data point, source, year]
  - Evidence: [data point, source, year]
- **Reason 3 (optional):** [sentence-conclusion]
  - Evidence: [data point, source, year]
- **Reason 4 (optional):** [sentence-conclusion]
  - Evidence: [data point, source, year]

MECE check: every reason should be mutually exclusive of the others (no overlap) and the set should be collectively exhaustive (together they fully support the governing idea). If two reasons restate each other, merge them. If the set leaves an obvious counter-argument unaddressed, add a reason or fold the rebuttal into an existing one.

## Transformation arc

Three sentences that map the audience's mental journey across the deck. Current state names where they stand today; insight names the new fact or reframing that changes the picture; future state names where the decision lands them.

- **Current state:** [one sentence]
- **Insight:** [one sentence: the pivot that the audience does not yet hold]
- **Future state:** [one sentence: the outcome the CTA produces]

The arc swings between what is and what could be. Pull its emotional weight from the audience brief: the future state answers the stakes-if-no field, and the insight is phrased for the chosen emotional lever (urgency: the cost of waiting; relief: the problem goes away; hope: what becomes possible; adrenaline: the race and the win).

## Call to action spec

Restate the audience brief's CTA in operational terms suitable for the closing slide. The brief's CTA names the actor and the action; the spec adds what the actor will literally see, sign, or vote on in the room.

- **Actor:** [same as audience brief]
- **Action (operational):** [the concrete artifact: a motion to vote, a budget line to approve, a document to sign, a name to commit]
- **Decision artifact:** [what the closing slide displays so the actor can act in the moment]
- **Timing:** [same as audience brief, restated as a session-bounded deadline]
- **Consequence if delayed (quantified):** [same as audience brief, with the number repeated so the room cannot forget it]

## Worked example: board intake-workflow approval

### SCQA opener

- **Situation:** The board has set a retention KPI of 92 percent first-year customer retention for FY26, tied to executive compensation.
- **Complication:** Onboarding cycle time has held above 10 weeks for six consecutive quarters and is the top customer-cited reason for first-year churn, putting the KPI out of reach on current trajectory.
- **Question:** What single intervention, available now, would move cycle time enough to recover the KPI in H2?
- **Answer:** Approve one intake workflow now to cut onboarding cycle time 35 percent in H2.

### Answer-first pyramid

- **Governing idea:** Approve one intake workflow now to cut onboarding cycle time 35 percent in H2.
- **Reason 1:** The cycle-time bottleneck is intake handoffs, not downstream provisioning, so a unified intake is the highest-leverage fix.
  - Evidence: Internal value-stream map (Ops, Q1 2026) shows 6.4 of 11 weeks are intake-side handoffs across 4 BUs.
  - Evidence: Customer-success post-mortems (n=42 churned accounts, H2 2025) cite "passed between teams" as the top friction descriptor.
- **Reason 2:** The two prior BU-led attempts failed for a reason a unified, PMO-owned workflow specifically resolves.
  - Evidence: 2024 retrospectives on both prior attempts cite "no cross-BU authority to enforce a shared SLA" as the root cause.
  - Evidence: PMO charter (board-approved Q4 2025) already grants the cross-BU authority that the prior attempts lacked.
- **Reason 3:** The 35 percent improvement is conservatively achievable in H2 because comparable peer rollouts have delivered it inside one quarter.
  - Evidence: Gartner intake-consolidation benchmark (2025): median 38 percent cycle-time reduction at 6 months post-rollout, n=23 peer firms.
  - Evidence: Vendor reference call with [peer firm], rolled out in Q2 2025, delivered 41 percent in 4 months.

MECE check: Reason 1 establishes the diagnosis (where the time goes), Reason 2 addresses the most likely objection (why this time is different), Reason 3 establishes feasibility of the headline number. No overlap; together they answer "is this the right fix, can we execute it, and will it deliver the promised result."

### Transformation arc

- **Current state:** The board sees intake reform as a perennial proposal that the BUs keep failing to deliver, and the retention KPI as slipping but recoverable next year.
- **Insight:** The KPI is not recoverable next year on current trajectory; the bottleneck is structurally cross-BU; and the authority gap that killed prior attempts has already been closed by the PMO charter.
- **Future state:** The board votes today, the PMO starts next sprint, cycle time hits 7.2 weeks by end of H2, and the retention KPI lands inside target with two quarters to spare.

### Call to action spec

- **Actor:** Board of directors, by formal vote.
- **Action (operational):** Approve the unified intake workflow scope and the associated H2 budget line (1.4M USD, detailed in the appendix).
- **Decision artifact:** A single motion shown on the closing slide, phrased so the chair can call the vote directly from the screen.
- **Timing:** Today, this session, before adjournment.
- **Consequence if delayed:** Cycle time stays at 11 weeks through year-end, projecting roughly 180 additional churn-attributable losses in H2, and the retention KPI tied to executive comp is forfeited.
