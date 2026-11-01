# Confidence labels

Every claim and thesis pillar in `synthesis.md` carries one line, `- Confidence: <label>`, under its `Independent sources: N` line. The label says how far a reader can rely on the claim. It is a separate line, so it never changes the claim's text, and claim checkers never see it.

## The rule

The first row that matches wins. N is the claim's `Independent sources: N`. An outcome counts only when the `claim:` line in `research/claim-checks.md` matches the claim's text now, and a `REFETCH:` mark only when its `claim:` line does.

| Row | The claim                                                                                                                 | Label line                     |
| --- | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| 1   | Outcome `REFUTED` (the user shipped it as-is), or marked `rejected` by the newest `synthesis-review-{n}.md` that lists it | `Confidence: low (refuted)`    |
| 2   | N is 1                                                                                                                    | `Confidence: low (one source)` |
| 3   | Outcome `UNCLEAR`                                                                                                         | `Confidence: low (unclear)`    |
| 4   | Outcome `UPHELD`, or `SKIPPED-CONFIRMED` with no `unresolved` mark in the newest review that lists it                     | `Confidence: high`             |
| 5   | Every other claim                                                                                                         | `Confidence: medium`           |

What this decides:

- **The check did not reach the claim.** Over the cap (`NOT-CHECKED`), `Claim cap: 0`, not testable, text changed since the last check, or the user said `ship as-is` at a check-in or stall before Step 7 ran: the label comes from N alone, so row 5 or row 2. No check, no `high`.
- **The check reached it and the refetch settled it.** `SKIPPED-CONFIRMED` is reached: `high` when N is 2 or more. A `confirmed` mark counts only through that outcome, so at a `ship as-is` before Step 7 it does not raise the label.
- **One source is low whatever the check says.** `UPHELD` or a `confirmed` refetch shows that the source says it, not that a second source agrees.
- **The user shipped a refuted claim.** It is `low (refuted)`, whatever N is, the report says the check contradicted it, and the Step 11 summary names it. A `rejected` claim shipped at a check-in or stall goes the same way.
- **`SPLIT` is medium**, by row 5.

## Who writes the label

1. The synthesis agent writes the provisional label on every iteration, from N alone: `medium`, or `low (one source)`. It never writes `high`.
2. The synthesis reviewer, in Check 7, flags a missing label, a `high` the rule does not give, and a `medium` when N is 1. Any other difference is no issue, since item 3 sets the final label.
3. You, the orchestrator, set the final labels before the writer starts (the next section).

## Set the final labels

`references/claim-check.md` section 5, the `ship as-is` of a synthesis check-in or stall, and the Step 10 PASS route send you here. Read `synthesis.md`, `claim-checks.md` if it exists, and the `REFETCH:` blocks of the `synthesis-review-{n}.md` files. For each claim and pillar, take the first row that matches and replace its `Confidence:` line in `synthesis.md`. Change no other line. Then check, with `S={OUTPUT_PATH}/research/synthesis.md`:

```bash
claims=$(grep -c '^ *- Claim:' "$S")
pillars=$(sed -n '/^## Argument Structure/,/^## [^A]/p' "$S" | grep -c '^[0-9]\+\. ')
labels=$(grep -cE '^ *- Confidence: (high|medium|low)( |$)' "$S")
echo "$claims $pillars $labels"
C=$(dirname "$S")/claim-checks.md; [ -f "$C" ] || C=/dev/null
awk 'FILENAME==ARGV[1] { if (/^ *claim: /) { c=$0; sub(/^ *claim: /,"",c) } else if (/^ *outcome: /) out[c]=$2; next }
/^## /{ sec=$0 }
/^ *- Claim: /{ c=$0; sub(/^ *- Claim: /,"",c); next }
sec ~ /Argument Structure/ && /^[0-9]+\. /{ c=$0; sub(/^[0-9]+\. /,"",c); next }
/- Independent sources: /{ n=$NF; next }
/- Confidence: /{ l=$0; sub(/^ *- Confidence: /,"",l); o=out[c]
  w=(o=="REFUTED")?"low (refuted)":(n==1)?"low (one source)":(o=="UNCLEAR")?"low (unclear)":(o=="UPHELD"||o=="SKIPPED-CONFIRMED")?"high":"medium"
  if (l!=w) print c " | " l " | table says " w }' "$C" "$S"
```

`labels` must equal `claims` plus `pillars`. Each line the `awk` prints is a label that differs from the table by outcome and N. The script cannot see `REFETCH:` marks, so a line may stay only when row 1's `rejected` mark or row 4's `unresolved` exception explains it. Fix any other line and run the check again. Then go on to the writer.
