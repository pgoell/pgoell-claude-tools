# Construct (Socratic) Orchestrator Playbook

**Purpose:** Build a pyramid turn-by-turn through interactive dialogue with the user. Mode D of the construct phase.

**This file is read by the orchestrator, NOT dispatched as an agent prompt.** Naming keeps symmetry with `construct-greenfield-prompt.md` and `construct-restructure-prompt.md`, but no `{OUTPUT_PATH}` substitution happens at dispatch time and no Agent tool is called. The orchestrator owns the loop end to end.

---

## Inputs

- `intake.md` (mode `socratic`, topic, audience, reader question, genre)
- The shipped reference (`pyramid-principle-reference.md`)
- The working directory `{OUTPUT_PATH}` (the orchestrator already knows this)

## Output

- `{OUTPUT_PATH}/construction.md` in the standard schema, written incrementally turn-by-turn with `<pending>` placeholders for unanswered nodes; the placeholders are replaced as turns complete and absent from the final pyramid.

## Turn Sequence (medium granularity)

Eleven turns for a three-sibling pyramid. Sibling and evidence turns scale with sibling count.

| Turn | AskUserQuestion text                                                                                                          | Micro-audit                                                                                                                   |
| ---- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 1    | _"What question do you expect the reader to have?"_ (pre-fill from `intake.md`'s `reader_question`; the user can edit)        | Question ends with `?` and is a real question, not a topic label. **Warn** otherwise.                                         |
| 2    | _"What is the apex, the one-sentence finding that answers that question?"_                                                    | **BLOCK:** Apex must be a sentence with a verb, not a noun phrase.                                                            |
| 3    | _"Below the apex, what one question does the apex raise for the reader?"_                                                     | Question downward must be distinct from Turn 1's reader question. **Warn** if identical.                                      |
| 4    | _"What plural noun names the children that will answer that question? (reasons, risks, steps, recommendations, causes, ...)"_ | Noun must be plural; pre-flags inductive vs deductive. **Warn** otherwise.                                                    |
| 5    | _"State the first finding."_                                                                                                  | **BLOCK:** label-vs-finding (must be a sentence with a verb). **Warn:** So-What ("would the reader say 'so what?' to this?"). |
| 6    | _"State the second finding."_                                                                                                 | **BLOCK:** label-vs-finding. **Warn:** ME overlap with finding 1.                                                             |
| 7    | _"State the third finding."_                                                                                                  | **BLOCK:** label-vs-finding. **Warn:** CE gap ("any obvious case missing?").                                                  |
| 8    | _"Add a fourth finding, or stop here?"_ (structured options: _Add one more / Stop at three / Add and stop at five_)           | **BLOCK:** Cap at 5; refuse 6+ with the MECE prompt below.                                                                    |
| 9+   | _"For finding 1, what evidence supports it? (one bullet per line)"_ (repeats per finding)                                     | **Warn:** Why-Is-That-True (each bullet is evidence, not restatement of the parent).                                          |

For four- or five-sibling pyramids, the sibling and evidence turns expand. Total turns scale with sibling count.

## Standard Escape Options on Every Turn

Every turn's `AskUserQuestion` carries these structured options alongside the freeform answer field:

- _Other (type my answer)_: primary path, where the user's answer goes.
- _Hand off remaining tiers to Mode A_: orchestrator updates state to `mode: greenfield, handoff_from: socratic`, dispatches `construct-greenfield-prompt.md` with `{HANDOFF}` set to `true`. The greenfield agent fills in the `<pending>` nodes only.
- _Pause and resume later_: orchestrator writes the state file with `mode: socratic`, `last_completed_phase: intake`. Emits a one-line confirmation and exits.
- _Cancel_: working directory artifacts left in place; state file entry removed.

Always present, every turn. No sentinel strings.

## Block List (the only blocking failures)

Three blocking failures. Everything else warns and accepts.

1. **Apex is a noun-phrase label, not a sentence with a verb (Turn 2).** Diagnostic:
   > _"That looks like a label, not a finding. A label names a topic ('Series B considerations'); a finding makes a claim ('We should raise Series B in Q1 2027'). What is your finding?"_
2. **Any sibling is a noun-phrase label (Turns 5-8).** Diagnostic: same shape as the apex one, customised to the sibling.
3. **Sibling count exceeds 5 (Turn 8 with _Add one more_ picked beyond five).** Diagnostic:
   > _"Six or more findings is a MECE-failure signal until proven otherwise. Apply the Four MECE Audit Questions (reference section 4) before defending the size: do any two findings overlap? Is there an obvious case missing? Could you consolidate or push some down a level?"_

After two failed attempts on the same hard-blocked turn (the user keeps tripping the same block), soften to a warning on the third attempt and accept the answer: _"Letting this through. The audit panel will flag it formally."_ Caps user frustration without abandoning the discipline.

## Soft-Warn Diagnostic Templates

For warnings that do NOT block, surface a single line, then accept the answer.

- **So-What (Turn 5+):** _"Would the reader say 'so what?' to this finding? If yes, push the consequence up a level."_
- **ME overlap (Turn 6+):** _"Does this overlap with a previous finding? If you described both to the reader, would they recognise two distinct ideas?"_
- **CE gap (Turn 7+):** _"Any obvious case the grouping skips? The audit panel runs a Four MECE Audit Questions check at the end."_
- **Why-Is-That-True (Turns 9+):** _"Each bullet should be evidence, not a restatement of the finding. Would the reader read this and say 'yes, because of that'?"_
- **Question downward not distinct from reader question (Turn 3):** _"The downward question should be distinct from the reader's. The reader asks 'should we raise?'; the apex answers 'yes, in Q1.' What new question does that answer raise?"_
- **Plural noun missing or singular (Turn 4):** _"A grouping of one or 'thoughts' usually signals the parent is not really a grouping. What plural noun names this group?"_

## Live Render Contract

After each accepted turn, write `construction.md` in this schema. `<pending>` placeholders mark nodes not yet reached.

```markdown
# Pyramid (construction)

**Mode:** socratic
**Apex (governing thought):** <user's answer from Turn 2, or `<pending>`>
**Reader question:** <user's answer from Turn 1, or `<pending>`>
**Top-level grouping noun:** <user's answer from Turn 4, or `<pending>`>
**Top-level logic:** inductive

## Subject

<from intake.md>

## Reader

<from intake.md>

## Siblings

### 1. <user's answer from Turn 5, or `<pending>`>

- Evidence:
  - <user's evidence from Turn 9, or `<pending>`>

### 2. <user's answer from Turn 6, or `<pending>`>

- Evidence:
  - <user's evidence from Turn 10, or `<pending>`>

### 3. <user's answer from Turn 7, or `<pending>`>

- Evidence:
  - <user's evidence from Turn 11, or `<pending>`>
```

After writing, emit a one-line progress summary to the user:

> _"Pyramid so far: apex + 2 of 3 siblings + 0 evidence rows. Next: finding 3."_

Single line. No full re-render in chat. The full pyramid is in `construction.md` for the user to inspect.

## Hand-Off Contract

When the user picks _Hand off remaining tiers to Mode A_ at any turn:

1. The orchestrator's live `construction.md` already has the locked nodes (with `<pending>` placeholders for unfinished ones), so no new write is needed.
2. Update the state file: `mode: greenfield`, add `handoff_from: socratic`.
3. Read `construct-greenfield-prompt.md`. Substitute the placeholders, with `{HANDOFF}` set to `true` and `{REVIEWER_FEEDBACK}` empty.
4. Dispatch via the Agent tool.
5. Verify `{OUTPUT_PATH}/construction.md` exists with no `<pending>` placeholders. The greenfield agent's `## Handoff mode` section is responsible for completing the missing nodes without modifying locked ones.
6. Mark Phase 2 task completed; proceed to Phase 3 (audit panel) as normal.

## Resume Contract

When the orchestrator detects a state file with `mode: socratic` and `last_completed_phase: intake`, ask via AskUserQuestion:

> _"In-flight Socratic dialogue found. Resume from <next-turn description>?"_

The `<next-turn description>` is inferred by reading `construction.md` and identifying the first `<pending>` field in turn order. Examples:

- Apex (Turn 2) is `<pending>` → "Resume from Turn 2: state your apex"
- Apex populated, downward question (Turn 3) is `<pending>` → "Resume from Turn 3: question the apex raises"
- Through Turn 4, plural noun is `<pending>` → "Resume from Turn 4: plural noun for the children"
- Sibling 1 (Turn 5) is `<pending>` → "Resume from Turn 5: state the first finding"
- All three siblings populated, evidence for finding 1 (Turn 9) is `<pending>` → "Resume from Turn 9: evidence for finding 1"

On yes, re-enter the turn loop at the inferred turn. On no, ask whether to start fresh, hand off the partial work to Mode A, or cancel.

## Behavioural Guidelines

- Inputs are FREEFORM only. Do NOT generate candidate findings, candidate apexes, or candidate evidence for the user to pick from. The whole reason Mode D exists is the writer's voice and thinking shaping every node.
- Block list is short and explicit. Do NOT block on So-What, ME, CE, Why-Is-That-True, downward question distinctness, or plural noun. Those warn and accept; the audit panel is the formal gate.
- After each accepted turn, the live render contract MUST run before the next `AskUserQuestion`. The user should always be able to inspect `construction.md` and see the current state of the pyramid.
- The escape options are always present. Every `AskUserQuestion`, every turn.
- The dialogue does NOT generate the SCQA opener. Phase 4 does that against the stable apex, like Modes A and B.
