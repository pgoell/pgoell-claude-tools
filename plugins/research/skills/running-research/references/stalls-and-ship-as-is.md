# Stalls, check-ins and `ship as-is`

The review loops of `SKILL.md` send you here: the synthesis loop (Steps 5 and 6) and the writer loop (Steps 9 and 10). Step 11 sends you to the last section.

## When to stop

**Stall.** After you write a `synthesis-review-{N}.md` or `draft-review-{N}.md` with verdict ISSUES, compare its critical issue ids to those of the review before it in the same loop. Minor ids do not count: one that comes and goes must not hide a repeat. If the two sets are the same, stop and send the message below. Never retry on your own. A PASS is never a stall. Skip this when the round came from a refuted claim: the review never lists its id, and Step 7 stops a claim that stays refuted.

**Check-in.** After iterations 3, 6, 9, ... of either loop, stop and send the same message.

## The message

Send all of this, then wait for the user's answer:

- The open critical issue ids, each with one line on what is wrong, then any minor ids.
- What you tried (which gap-fills or rewrites ran), and what closed since iteration 1. At a stall, say the last round closed none of these ids.
- For each `weak-source-<claim-slug>` id: this thesis pillar rests on one weak source (say if a gap-fill looked for a stronger one and found none), and the id stays until one exists or the pillar changes. Shipped as it is, the pillar stays `low (one source)`, and the report names its source.
- The three options, each with what it does:
  - `continue`: one more round on these ids. At a stall, say it repeats a round that closed none, so it fits only when something should differ this time.
  - `ship as-is`: the cost line below.
  - `intervene`: the user says what to change (drop or reword a claim, name a source, narrow the scope). Make that change through the same loop: a new synthesis or draft, then a new review.

The cost line depends on the loop.

- Synthesis loop: "`ship as-is` skips the claim check. A claim can be `high` only if an earlier claim check cleared it in these same words, so every other claim is `medium` at best. The open critical issues stay open, and the final summary names them."
- Writer loop: "`ship as-is` keeps the current draft and its labels. The open critical issues stay open, and the final summary names them."

## After `ship as-is`

- Synthesis loop: set the labels as `references/confidence-labels.md` says, then go to Step 8, or back to the writer as Step 10 says.
- Writer loop: go to Step 11 with the current draft.

## The end summary

Step 11 tells the user, in this order:

1. Total iterations of each loop and the final paths (`report.html` and `report.md`; `report.md` alone for markdown or a failed render).
2. Every critical issue left open, from the newest review of each loop. A loop ends with a critical issue only after a `ship as-is`, so this prints nothing on a clean run:

   ```bash
   O="{OUTPUT_PATH}"
   for f in "$(ls "$O"/research/synthesis-review-*.md | sort -V | tail -1)" "$(ls "$O"/draft-review-*.md | sort -V | tail -1)"; do
     awk '/^ *- id: /{ id=$3; c=0 } /^ *severity: critical/{ c=1 }
     /^ *description: /&&c{ d=$0; sub(/^ *description: /,"",d); print id ": " d }' "$f"
   done
   ```

3. Any minor issues from those same reviews.
4. Every claim or pillar `synthesis.md` labels `Confidence: low (refuted)`, and whether the check or the refetch contradicted it.
5. Every claim still there in other words whose old text a check found wrong: listed `REFUTED` in `claim-checks.md`, or marked `rejected` in a `REFETCH:` block. Say: reworded, not checked again. Leave out a claim whose text now has a `confirmed` mark or an outcome other than `NOT-CHECKED`.
