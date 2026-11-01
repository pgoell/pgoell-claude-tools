#!/usr/bin/env bash
# Tests the researcher file filter that synthesis-prompt.md and
# synthesis-reviewer-prompt.md each hold, the label check of
# references/confidence-labels.md and the open-issue list of
# references/stalls-and-ship-as-is.md, as the files print them. No network.
# Run from the repo root: bash plugins/research/tests/run.sh
set -uo pipefail

SKILL="$(cd "$(dirname "$0")/../skills/running-research" && pwd)"

pass=0
fail=0
ok() {
  echo "ok   $1"
  pass=$((pass + 1))
}
bad() {
  echo "FAIL $1"
  fail=$((fail + 1))
}

# Prints the filter command the prompt $1 holds, as a dispatched agent reads it.
filter_of() {
  sed -n 's/^ *ls {OUTPUT_PATH}\/research\/\*\.md | //p' "$1"
}

A="$(filter_of "$SKILL/synthesis-prompt.md")"
B="$(filter_of "$SKILL/synthesis-reviewer-prompt.md")"
[ -n "$A" ] && ok "synthesis-prompt.md holds a filter" || bad "synthesis-prompt.md holds a filter"
[ "$A" = "$B" ] && ok "both prompts hold the same filter" || bad "both prompts hold the same filter"

# keeps $1 file: the filter must print the path.
keeps() {
  [ "$(printf '%s\n' "$1" | bash -c "$A")" = "$1" ] && ok "keeps $1" || bad "keeps $1"
}
# drops $1 file: the filter must print nothing.
drops() {
  [ -z "$(printf '%s\n' "$1" | bash -c "$A")" ] && ok "drops $1" || bad "drops $1"
}

# The repeat command of issue 312.
keeps /o/research/gap-3-refetch-peer-review-share.md

keeps /o/research/pricing.md
keeps /o/research/gap-1-pricing.md
keeps /o/research/peer-review-share.md
keeps /o/research/synthesis-methods.md
keeps /o/research/gap-2-synthesis-review-methods.md

drops /o/research/synthesis.md
drops /o/research/claim-checks.md
drops /o/research/synthesis-review-1.md
drops /o/research/synthesis-review-12.md

# A folder name in OUTPUT_PATH must not hide the folder's files.
keeps /reports/peer-review-2026/research/pricing.md
keeps /reports/synthesis-of-x/research/pricing.md
drops /reports/peer-review-2026/research/synthesis.md

# Prints the first bash block of the markdown file $1, with its indent gone.
block_of() {
  awk '/^ *```bash$/{ on=1; next } /^ *```$/{ if (on) exit } on' "$1" | sed 's/^   //'
}

LABELS="$SKILL/references/confidence-labels.md"
STALLS="$SKILL/references/stalls-and-ship-as-is.md"
CHECK="$(block_of "$LABELS")"
OPEN="$(block_of "$STALLS")"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

# A case: one claim X with $2 independent sources and label $3. $4 is the
# outcome in claim-checks.md (or -). The rest are the marks of reviews 1, 2, ...
# for X, with - for a review that does not list it. A + joins marks on two URLs.
label_case() {
  local name="$1" n="$2" label="$3" outcome="$4" i=1 m
  shift 4
  local o="$T/c"
  rm -rf "$o"
  mkdir -p "$o"
  printf '## Claims\n\n- Claim: X\n  - Independent sources: %s\n  - Confidence: %s\n' "$n" "$label" >"$o/synthesis.md"
  [ "$outcome" = - ] || printf '# Claim Checks (Round 1)\n\nCLAIMS:\n\n- id: claim-check-x\n  claim: X\n  outcome: %s\n' "$outcome" >"$o/claim-checks.md"
  for m in "$@"; do
    { printf '# Synthesis Review (Iteration %s)\n\nREFETCH:\n' "$i"
      [ "$m" = - ] || for k in ${m//+/ }; do printf '  - url: https://a.example\n    claim: X\n    mark: %s\n' "$k"; done
    } >"$o/synthesis-review-$i.md"
    i=$((i + 1))
  done
  local out
  out="$(S="$o/synthesis.md" bash -c "$CHECK" 2>&1 | tail -n +2)"
  [ -z "$out" ] && ok "labels: $name" || bad "labels: $name: $out"
}

# The steps of issue 316.
label_case "older rejected, later UPHELD is high" 2 high UPHELD rejected -
label_case "older rejected, later UNCLEAR is low (unclear)" 2 "low (unclear)" UNCLEAR rejected -
label_case "older rejected, later SPLIT is medium" 2 medium SPLIT rejected -
label_case "older rejected, no check is medium" 2 medium - rejected -
# Shipped over a mark in the last review.
label_case "rejected in last review, no check" 2 "low (refuted)" - rejected
label_case "rejected in last review beats older UPHELD" 2 "low (refuted)" UPHELD confirmed rejected
label_case "rejected carried past the limit beats UPHELD" 2 "low (refuted)" UPHELD rejected rejected
label_case "rejected beats confirmed in one review" 2 "low (refuted)" - confirmed+rejected
label_case "rejected with one source is refuted" 1 "low (refuted)" - rejected
# The other rows hold.
label_case "REFUTED shipped" 2 "low (refuted)" REFUTED
label_case "one source upheld stays low" 1 "low (one source)" UPHELD confirmed
label_case "skipped confirmed is high" 2 high SKIPPED-CONFIRMED confirmed
label_case "new unresolved lowers skipped confirmed" 2 medium SKIPPED-CONFIRMED confirmed unresolved
label_case "not checked is medium" 2 medium NOT-CHECKED
label_case "no reviews, no checks" 2 medium -

# The check must also catch a wrong label, not only pass right ones.
wrong="$(cd "$T" && mkdir -p w && printf '## C\n\n- Claim: X\n  - Independent sources: 2\n  - Confidence: low (refuted)\n' >w/synthesis.md &&
  printf '# Synthesis Review (Iteration 1)\n\nREFETCH:\n  - url: u\n    claim: X\n    mark: rejected\n' >w/synthesis-review-1.md &&
  printf '# Synthesis Review (Iteration 2)\n\nREFETCH:\n' >w/synthesis-review-2.md &&
  printf 'CLAIMS:\n\n- id: i\n  claim: X\n  outcome: UPHELD\n' >w/claim-checks.md &&
  S=w/synthesis.md bash -c "$CHECK" | tail -n +2)"
[ "$wrong" = "X | low (refuted) | table says high" ] && ok "labels: flags low (refuted) on a later UPHELD" || bad "labels: flags low (refuted) on a later UPHELD: $wrong"

# The open critical issues come from the newest review of each loop.
O="$T/my reports"
mkdir -p "$O/research"
review() {
  printf 'VERDICT: ISSUES\n\nISSUES:\n  - id: %s\n    severity: %s\n    category: logic\n    description: %s\n    location: x\n\nSUMMARY:\ndone\n' "$2" "$3" "$4" >"$1"
}
review "$O/research/synthesis-review-2.md" old-gone critical "closed since"
review "$O/research/synthesis-review-10.md" weak-source-x critical "pillar on one vendor"
review "$O/draft-review-1.md" draft-minor minor "a small thing"
listed="$(OPENDIR="$O" bash -c "$(printf '%s\n' "$OPEN" | sed 's/^O="{OUTPUT_PATH}"$/O="$OPENDIR"/')")"
[ "$listed" = "weak-source-x: pillar on one vendor" ] && ok "open critical issues: newest review only, no minor" || bad "open critical issues: $listed"
review "$O/draft-review-2.md" draft-crit critical "draft distorts X"
listed="$(OPENDIR="$O" bash -c "$(printf '%s\n' "$OPEN" | sed 's/^O="{OUTPUT_PATH}"$/O="$OPENDIR"/')" | tail -1)"
[ "$listed" = "draft-crit: draft distorts X" ] && ok "open critical issues: the writer loop too" || bad "open critical issues, writer loop: $listed"

# Words the rules depend on.
has() {
  grep -qF "$2" "$1" && ok "$3" || bad "$3"
}
has "$LABELS" 'marked `rejected` by the last `synthesis-review-{n}.md`' "row 1 reads the last review"
has "$STALLS" 'compare its critical issue ids' "a stall compares critical ids"
has "$STALLS" 'every other claim is `medium` at best' "the message names the cost of skipping the check"
has "$STALLS" '`weak-source-<claim-slug>`' "the message explains a weak source id"
has "$SKILL/synthesis-reviewer-prompt.md" 'copy it with `mark: rejected`' "a rejected claim past the limit keeps its mark"
has "$SKILL/references/claim-check.md" 'is checked whatever the cap' "a claim once found wrong passes the cap"
has "$SKILL/synthesis-reviewer-prompt.md" 'the URLs synthesis.md cites for it now' "the refetch follows the claim"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
