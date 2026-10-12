#!/bin/bash
# usage: tests/digest.sh
# Runs the digest skill's review.py and remember.py against one fixture: a
# problem proposed on two days whose verdict the later id holds. No session,
# no network. Needs bash, jq and uv.
set -u
here=$(cd "$(dirname "$0")" && pwd)
scripts="$here/../skills/digest/scripts"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got '$2', want '$3'"; fi; }

D=2026-10-08
IN="$T/vault/01 Periodic/06 Insights"
mkdir -p "$IN/memory"
args=(--vault "$T/vault" --date "$D")
mem() { echo "{\"fingerprint\":\"worktree-guard-compound\",\"ids\":[\"10-08-07\",\"10-10-01\"],\"verdict\":\"applied\",\"verdict_id\":\"$1\",\"verdict_date\":\"2026-10-10\",\"ref\":\"https://github.com/me/app/pull/358\",\"title\":\"t\",\"action\":\"Opens a PR\",\"total\":3}" >"$IN/memory/problems.jsonl"; }
m() { jq -r "$1" "$IN/memory/problems.jsonl"; }
review() { uv run -q "$scripts/review.py" "${args[@]}" | jq -r "$1"; }
record() {
  echo "[{\"fingerprint\":\"worktree-guard-compound\",\"id\":\"$1\",\"verdict\":\"rejected\",\"reason\":\"\"}]" >"$T/verdicts.json"
  uv run -q "$scripts/remember.py" "${args[@]}" --verdicts "$T/verdicts.json"
}

echo '{"problems":[{"id":"10-08-07","fingerprint":"worktree-guard-compound","title":"t","destination":"app"}]}' >"$IN/$D.json"
printf '# Insights %s\n\n## Keep\n\n' "$D" >"$IN/$D.md"

# the later id holds the verdict: the earlier id's deleted line is settled, not dropped
mem 10-10-01
ok "earlier id handled" "$(review '.handled|map("\(.id) \(.verdict)")|join(",")')" "10-08-07 applied"
ok "earlier id not dropped" "$(review '.dropped|length')" 0
ok "note done" "$(review .state)" done
ok "earlier id recorded" "$(record 10-08-07)" "recorded 0 verdicts in $IN/memory/problems.jsonl, 1 already held"
ok "later verdict stays" "$(m '"\(.verdict) \(.verdict_id) \(.ref)"')" "applied 10-10-01 https://github.com/me/app/pull/358"

# the later id may still change its own verdict
record 10-10-01 >/dev/null
ok "later id recorded" "$(m '"\(.verdict) \(.verdict_id)"')" "rejected 10-10-01"

# a verdict on the earlier id settles nothing for a later one
mem 10-08-07
sed -i 's/"id":"10-08-07"/"id":"10-10-01"/' "$IN/$D.json"
ok "later id not handled" "$(review '.handled|length')" 0
ok "later id dropped" "$(review '.dropped|map(.id)|join(",")')" 10-10-01

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
