# Claim check

Step 7 sends you here. You, the orchestrator, pick the claims, dispatch the checkers and write `{OUTPUT_PATH}/research/claim-checks.md`. Checkers write no file.

## 1. Pick the claims

Read `synthesis.md`. List its testable claims in this order, in file order within each kind: numbers (amounts and deal terms too), then names and dates, then thesis pillars. A testable claim states something a page could contradict and has at least one cited source; leave out the rest. A thesis pillar takes the sources of the claims it rests on. A claim gets the id `claim-check-<claim-slug>`; the slug never holds `-review-`, which the researcher file filter drops. A claim reworded in a later round is the same claim when it makes the same point on the same subject: it keeps its id.

Sort each claim into one group, first match wins:

1. `SKIPPED-CONFIRMED`: a `confirmed` mark in the `REFETCH:` block of any `synthesis-review-{n}.md`, whose `claim:` line matches the claim's text now. The newest review that lists the claim must hold no `rejected` or `unresolved` mark for it, and `claim-checks.md` must not list it as `REFUTED`.
2. Carried: `claim-checks.md` lists the claim with votes, and its text is unchanged. It keeps its votes and outcome, and no one checks it again.
3. To check: every other claim, up to the cap. Changed text is a new check under the same id.
4. `NOT-CHECKED`: the claims past the cap.

The cap is 15 claims per run, unless `brief.md` has a line `Claim cap: N`, which replaces it (0 checks nothing). If N is not a whole number, use 15 and tell the user. Count each id once, including carried claims and claims checked in an earlier round; skipped claims do not count.

## 2. Tell the user the cost

Calls are 3 per claim to check. When this round's calls plus the calls of earlier rounds pass 30, tell the user the count before you dispatch ("Claim check: 36 agent calls for 12 claims"). Then go on without waiting. A claim whose text changed costs 3 more calls, so a run with rework can pass 45.

## 3. Dispatch

For each claim to check, read `references/claim-checker-prompt.md`. Inject CLAIM (as `synthesis.md` states it) and SOURCES (its source entries word for word, with tag and `origin:`, and its `Independent sources: N` line). Inject nothing else: no brief, no `Confidence:` line, no synthesis, no path. Send 3 fresh checkers per claim, all in parallel when supported.

If the platform cannot dispatch subagents, run the three checks inline, one after another, each from the same two inputs, and tell the user they were less independent.

A reply fails when it does not end on the three lines of the template, or a `REFUTED` or `UPHELD` has no quote or no URL. Re-dispatch that checker once. If it fails again, its vote is `UNCLEAR`, with quote `checker failed`.

## 4. Count and write

Outcome per claim: `REFUTED` on 2 or more `REFUTED` votes; `UPHELD` on 2 or more `UPHELD`; `UNCLEAR` on 2 or more `UNCLEAR`; `SPLIT` on one of each.

Rewrite `{OUTPUT_PATH}/research/claim-checks.md` each round (R is 1 on the first run of Step 7, then one more each run), on every run of Step 7, also when nothing needed a check. List every claim. A claim gone from `synthesis.md` leaves the file.

```markdown
# Claim Checks (Round R)

CLAIMS:

- id: claim-check-<claim-slug>
  claim: <as synthesis.md states it>
  sources: <URL>, <URL>
  outcome: REFUTED | UPHELD | UNCLEAR | SPLIT | SKIPPED-CONFIRMED | NOT-CHECKED
  votes: REFUTED <n>, UPHELD <n>, UNCLEAR <n>
  evidence:
  - <VOTE> <URL> "<quote>"
```

`votes` and `evidence` stay empty for `SKIPPED-CONFIRMED` and `NOT-CHECKED`.

## 5. Route

Before any route to the writer, set the final labels: read `references/confidence-labels.md` and follow it.

- An id that was `REFUTED` in the last round and is `REFUTED` again, carried or checked anew: Step 6 did not fix the claim, so stop and surface it to the user. Read the old file before you rewrite it. Options: `continue` (another Step 6 round on every refuted claim), `ship as-is` (go on as for no `REFUTED`; the claim stays `REFUTED`, and Step 11 names it), `intervene`.
- Otherwise, any new `REFUTED`: each is a critical `source-quality` issue with the claim's id. Go to Step 6, with N the last synthesis review's iteration. The loop returns through Step 5 to Step 7.
- No `REFUTED`: go on to Step 8, or back to the writer as Step 10 says when Step 10 sent you to Step 6. `UPHELD`, `UNCLEAR` and `SPLIT` do not block.
