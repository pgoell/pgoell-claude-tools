# Review Loop

The orchestration layer: judge prompts, verifier prompts, the ledger, termination, and a Workflow script template. The main session drives rounds and applies fixes; judges and verifiers are fresh subagents with no conversation context. That isolation is the load-bearing property; without it the loop self-approves.

## Judge protocol

Three habits make vision judges more reliable, and every prompt in this file follows them:

- **Checklists, not scores.** A judge answers one yes/no question per rule per slide and never gives an overall or aesthetic score. Per-item checks track human judgment better than one holistic number.
- **A named flaw taxonomy.** The visual judge and the default render check receive the F items from the constitution with their definitions; a judge told what to look for finds more.
- **Screenshots first, at full size.** Screenshots stay at 1920x1080 (never downscaled) and come before the text in the prompt and in the reading order. Probe output in `for-judges.json` comes after.

Absolute pass/fail items suit rule compliance. For choosing between two versions (before and after a fix, two visual directions), use the pairwise prompt below instead: judges rank two options far better than they score one.

## Judge prompt

One judge per soft dimension (`narrative`, `clarity`, `visual`, `delivery`), all four in parallel, fresh every round. Rules per dimension: narrative S1 to S4; clarity S5 to S8 and S17, plus the H8 warnings in `for-judges.json`; visual S9 to S13, V1 to V13, and F1 to F7, plus the H6, H7, and H9 entries in `for-judges.json`; delivery S14 to S16. Template (fill the angle brackets):

```
You are reviewing a slide deck against an explicit standards document. You review; you never fix.

First, look at every slide screenshot in order, at full size: <list of slide-NN.png paths>

Standards document (the only source of valid findings):
<full text of deck-standards.md, including the deck brief, plus the preset's guidelines.md and language.md (or the default preset's language.md)>

Your dimension: <dimension>. Your checklist: <rule IDs for this dimension>.
Work through the checklist one rule at a time. For each rule, decide for each slide: does
this slide break the rule, yes or no? Every "yes" is a finding. Do not give any overall or
aesthetic score.

Other materials, after the screenshots:
- Deck source: <deck html path> (read it for text content, notes, and structure)
- Probe notes for judgment: <for-judges.json path> (hints, not findings; confirm on the screenshot)

Rules of evidence:
- Every finding must cite exactly one rule ID and one slide number, with concrete evidence
  (quote the text or describe what is visibly wrong in the screenshot).
- Judge against the standards document and the deck brief, not your taste. If a rule does not
  forbid it, it is not a finding.
- Do not propose rewrites or fixes. Findings only.
- An empty findings list is a fully acceptable answer. Do not invent findings to seem thorough.

Severity scale: blocker, major, minor, nit, as defined in the standards document.
```

Findings schema (use as the structured-output schema for `agent()`):

```json
{
  "type": "object",
  "required": ["findings"],
  "properties": {
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["rule", "slide", "severity", "evidence"],
        "properties": {
          "rule": { "type": "string" },
          "slide": { "type": "integer" },
          "severity": { "enum": ["blocker", "major", "minor", "nit"] },
          "evidence": { "type": "string" }
        }
      }
    }
  }
}
```

## Verifier prompt

One verifier per finding by default; three with majority vote for blockers and for every finding in strict mode. The verifier is prompted to refute, not to confirm:

```
A deck reviewer raised this finding. Your job is to try to REFUTE it.

First look at the screenshot of that slide, at full size: <slide-NN.png path>

Standards document: <full text>
Finding: rule <rule>, slide <slide>, severity <severity>: <evidence>
Deck source: <deck html path>

Refute it if ANY of these hold:
- The cited rule does not actually say what the finding needs it to say.
- The evidence is not real (the screenshot or source does not show it).
- The severity is inflated by more than one level (then correct it instead of refuting).
- The finding contradicts the deck brief's stated constraints.

If you cannot refute it on those grounds, uphold it. Uncertainty about taste is not
grounds to uphold; the finding must be solid against the written rule.
```

Verdict schema:

```json
{
  "type": "object",
  "required": ["verdict"],
  "properties": {
    "verdict": { "enum": ["uphold", "refute"] },
    "correctedSeverity": { "enum": ["blocker", "major", "minor", "nit"] },
    "reason": { "type": "string" }
  }
}
```

## Default render check

Runs after every build, before the deck is handed over, without asking. It is the cheap version of a round: hard gates plus one outside look.

1. Run H1 to H9 (`hard-gates.md`, `copy-lint.md`) and capture full-size screenshots to `.deck-review/check-<N>/`.
2. Fix every hard-gate failure. Re-run the gates until they pass or the cap is reached.
3. Dispatch one fresh subagent with the prompt below. It sees the screenshots, the flaw taxonomy, and the probe notes, nothing else: not the conversation, not the deck brief's history.
4. Fix each flaw it reports with the smallest change, re-render only the changed slides, and repeat from step 1 on those slides.

Stop after two fix rounds by default, three at most; then report what is still open instead of looping. No verifier stage: the check is narrow on purpose, and anything contested belongs in the full loop. Without subagent dispatch, run the hard gates only and say that the outside look was skipped.

```
You are checking rendered slides for layout defects. You report; you never fix.

First, look at every screenshot in order, at full size: <list of slide-NN.png paths>

For each slide, answer each question yes or no:
<F1 to F7 from the constitution, with their definitions>

Then read the probe notes (hints, not findings; confirm each on the screenshot before
reporting it): <for-judges.json path>

Report only the "yes" answers, one finding per flaw per slide, citing the F item and saying
exactly where on the slide it is (which element, which edge). No overall score, no taste,
no rewrites. An empty list is a valid answer.
```

The findings schema is the one below, with `rule` holding the F item.

## Pairwise prompt

For a before/after comparison of a slide or for choosing between visual directions. Always exactly two candidates, always two calls with the order swapped, each in a fresh subagent:

```
Two versions of the same slide (or two sample slides for the same deck) follow.
First look at both images at full size: A = <path>, B = <path>.

Brief: <deck brief, and for directions the subject and audience>
Criteria: <the rules that decide this comparison, for example S8, S10, V2, V8, F1 to F7;
for directions add: fits the subject and audience, passes the palette-swap test>

Which one better meets the criteria? Answer A or B, with one sentence per criterion that
decided it. Do not score either one.
```

Run it once as (A = first, B = second) and once swapped. Both calls pick the same candidate: it wins. They disagree: call it a tie, keep the current version (before/after) or show both to the user (directions). Never break a tie with a third call in the same order.

## The ledger

`.deck-review/ledger.json`, owned by the main session:

```json
{
  "entries": [
    {
      "key": "S5:3:cost analysis",
      "status": "rejected",
      "round": 2,
      "reason": "..."
    }
  ]
}
```

- Key: `<rule>:<slide>:<first six significant words of the evidence, lowercased>`.
- Statuses: `rejected` (verifier refuted it), `fixed` (confirmed and resolved).
- Before verification each round, drop any new finding whose key matches a `rejected` entry; it was already litigated. A match against a `fixed` entry stays in: that is a regression and should alarm, not be dismissed.
- Slide indices shift when slides are added or removed; after any such fix, re-key the ledger by slide content, not position (or accept a few re-litigated findings that round).

## Round flow and termination

```
round R:
  hard gates H1-H9 + screenshots    (deterministic, references/hard-gates.md)
  judges x4 in parallel             (fresh subagents)
  ledger filter                     (drop re-litigated rejections)
  verify each survivor              (adversarial; 3-way majority for blockers / strict mode)
  fix = hard-gate failures + upheld findings at or above threshold
  if fix list empty: dryRounds += 1 else dryRounds = 0; apply fixes
  done when dryRounds == 2, or round == cap (default 5, then report open items)
```

Fix discipline: smallest change that resolves the citation, hard gates first, one commit per round so every round is diffable.

## Workflow script (one invocation per round)

The main session runs hard gates and screenshots first, then invokes this per round with `args = { standardsPath, deckPath, screenshots: [...], rejectedKeys: [...], strict: false }`. It returns confirmed and rejected findings; the main session updates the ledger, fixes, and decides termination.

```js
export const meta = {
  name: 'deck-review-round',
  description: 'One review round: 4 dimension judges, adversarial verification per finding',
  phases: [
    { title: 'Review', detail: 'one fresh judge per soft dimension' },
    { title: 'Verify', detail: 'adversarial refutation per finding' },
  ],
}
const FINDINGS = { /* findings schema from above */ }
const VERDICT = { /* verdict schema from above */ }
const DIMENSIONS = ['narrative', 'clarity', 'visual', 'delivery']
const key = (f) => `${f.rule}:${f.slide}:` + f.evidence.toLowerCase().split(/\W+/).filter(w => w.length > 2).slice(0, 6).join(' ')
const judgePrompt = (dim) => `...judge template above, filled with args.standardsPath contents, ${dim}, args.screenshots, args.deckPath...`
const verifyPrompt = (f) => `...verifier template above, filled with the finding and its slide screenshot...`

const results = await pipeline(
  DIMENSIONS,
  (dim) => agent(judgePrompt(dim), { label: `judge:${dim}`, phase: 'Review', schema: FINDINGS }),
  (review) => {
    const fresh = (review?.findings || []).filter(f => !args.rejectedKeys.includes(key(f)))
    return parallel(fresh.map(f => () => {
      const votes = (f.severity === 'blocker' || args.strict) ? 3 : 1
      return parallel(Array.from({ length: votes }, (_, i) =>
        () => agent(verifyPrompt(f), { label: `verify:${f.rule}:s${f.slide}:v${i}`, phase: 'Verify', schema: VERDICT })))
        .then(vs => ({ ...f, verdicts: vs.filter(Boolean) }))
    }))
  }
)
const judged = results.filter(Boolean).flat().filter(Boolean)
const upheldBy = (f) => f.verdicts.filter(v => v.verdict === 'uphold').length > f.verdicts.length / 2
return {
  confirmed: judged.filter(upheldBy).map(f => ({ ...f, severity: f.verdicts.find(v => v.correctedSeverity)?.correctedSeverity || f.severity })),
  rejected: judged.filter(f => !upheldBy(f)).map(f => ({ key: key(f), reason: f.verdicts.map(v => v.reason).join('; ') })),
}
```

Inline the actual prompt texts and schemas; the script must be self-contained. Judges and verifiers read the screenshots and deck source from disk via their own tools, so pass paths, not file contents, in the prompts (except the standards document, which is short enough to inline and must not drift mid-round).

## Fallback without the Workflow tool

Dispatch the four judges as parallel Agent calls with the same prompts and ask each to end with the findings as a JSON code block. Then dispatch verifiers the same way. Parse, filter through the ledger, fix, loop. Slower, same isolation guarantees.
