#!/usr/bin/env bash
# Tests the researcher file filter that synthesis-prompt.md and
# synthesis-reviewer-prompt.md each hold. No network.
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

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
