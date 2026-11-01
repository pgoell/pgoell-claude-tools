# Confidence labels

Every claim and thesis pillar in `synthesis.md` carries one line, `- Confidence: <label>`, under its `Independent sources: N` line. The label says how far a reader can rely on the claim. It is a separate line, so it never changes the claim's text, and claim checkers never see it.

## The rule

The first row that matches wins. N is the claim's `Independent sources: N`. An outcome counts only when the `claim:` line in `research/claim-checks.md` matches the claim's text now.

| Row | The claim                                                                                                                 | Label line                     |
| --- | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| 1   | Outcome `REFUTED` (the user shipped it as-is), or marked `rejected` by the newest `synthesis-review-{n}.md` that lists it | `Confidence: low (refuted)`    |
| 2   | N is 1                                                                                                                    | `Confidence: low (one source)` |
| 3   | Outcome `UNCLEAR`                                                                                                         | `Confidence: low (unclear)`    |
| 4   | Outcome `UPHELD` or `SKIPPED-CONFIRMED`                                                                                   | `Confidence: high`             |
| 5   | Every other claim                                                                                                         | `Confidence: medium`           |

What this decides:

- **The check did not reach the claim.** Over the cap (`NOT-CHECKED`), `Claim cap: 0`, not testable, text changed since the last check, or the user said `ship as-is` at a check-in before Step 7 ran: the label comes from N alone, so row 5 or row 2. No check, no `high`.
- **The check reached it and the refetch settled it.** `SKIPPED-CONFIRMED` is reached: `high` when N is 2 or more.
- **One source is low whatever the check says.** `UPHELD` or a `confirmed` refetch shows that the source says it, not that a second source agrees.
- **The user shipped a refuted claim.** It is `low (refuted)`, whatever N is, and the report says the check contradicted it.
- **`SPLIT` is medium**, by row 5.

## Who writes the label

1. The synthesis agent writes the provisional label on every iteration, from N alone: `medium`, or `low (one source)`. It never writes `high`.
2. The synthesis reviewer, in Check 7, flags a missing label and a label higher than the rule allows. A lower label is no issue, since item 3 sets the final one.
3. You, the orchestrator, set the final labels before the writer starts (the next section).

## Set the final labels

`references/claim-check.md` section 5 and the check-in `ship as-is` send you here. Read `synthesis.md`, `claim-checks.md` if it exists, and the `REFETCH:` blocks of the `synthesis-review-{n}.md` files. For each claim and pillar, take the first row that matches and replace its `Confidence:` line in `synthesis.md`. Change no other line. Then check, with `S={OUTPUT_PATH}/research/synthesis.md`:

```bash
claims=$(grep -c '^ *- Claim:' "$S")
pillars=$(sed -n '/^## Argument Structure/,/^## [^A]/p' "$S" | grep -c '^[0-9]\+\. ')
labels=$(grep -cE '^ *- Confidence: (high|medium|low)( |$)' "$S")
highs=$(grep -c '^ *- Confidence: high' "$S")
reached=$(grep -cE '^ *outcome: (UPHELD|SKIPPED-CONFIRMED)$' {OUTPUT_PATH}/research/claim-checks.md 2>/dev/null)
echo "$claims $pillars $labels $highs ${reached:-0}"
```

`labels` must equal `claims` plus `pillars`, and `highs` must not pass `reached`. When a check fails, fix the lines and run it again. Then go on to the writer.
