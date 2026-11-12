#!/usr/bin/env bash
# Drives judge/compare.py end to end (run, judge, report) with a fake
# `claude` binary, so it needs no network and no account.
# Run from the repo root: bash plugins/writing/tests/run.sh
set -uo pipefail

JUDGE="$(cd "$(dirname "$0")/../judge" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
check() {
  if [ "$2" = 0 ]; then
    echo "ok   $1"
    pass=$((pass + 1))
  else
    echo "FAIL $1"
    fail=$((fail + 1))
  fi
}

# The fake answers a case with a line that names its skill prefix, and
# answers the judge prompt with a verdict that fails every answer written
# without a skill and ranks those last.
cat >"$TMP/claude" <<'EOF'
#!/usr/bin/env python3
import json, re, sys
prompt = sys.argv[sys.argv.index("-p") + 1]
if "independent judge" in prompt:
    outs = re.findall(r'<output label="(\w)">\n(.*?)\n</output>', prompt, re.S)
    bad = [l for l, t in outs if "no skill" in t]
    good = [l for l, t in outs if "no skill" not in t]
    verdict = {"outputs": {}, "ranking": good + bad}
    for label, _ in outs:
        failed = label in bad
        verdict["outputs"][label] = {
            "hard_gate_fail": failed, "gate_reason": "invented a fact" if failed else "",
            "requirements_met": not failed, "evidence": "fake",
            "scores": {d: 2 if failed else 4 for d in ["task_fit", "fidelity", "substance", "authorship", "structure", "craft"]},
        }
    result = "Here is the verdict:\n" + json.dumps(verdict)
else:
    result = "answer from " + (prompt.split()[0] if prompt.startswith("/") else "no skill")
print(json.dumps({"result": result, "total_cost_usd": 0.01, "usage": {"output_tokens": 10}}))
EOF
chmod +x "$TMP/claude"
mkdir "$TMP/plug"

cmp() { python3 "$JUDGE/compare.py" "$@"; }

cmp run --out "$TMP/o" --claude "$TMP/claude" --runs 2 \
  --condition baseline --condition "skill=/a:b@$TMP/plug" >"$TMP/run.log" 2>&1
check "run exits 0" $?
cases=$(python3 -c "import json;print(len(json.load(open('$JUDGE/cases.json'))['cases']))")
[ "$(find "$TMP/o/outputs" -name '*.json' | wc -l)" = $((cases * 4)) ]
check "run writes one output per case, condition and run" $?
grep -q '"answer from /a:b"' "$TMP/o/outputs/"*__skill__1.json
check "the skill prefix reaches the prompt" $?

cmp run --out "$TMP/o" --claude /nonexistent --runs 2 \
  --condition baseline --condition "skill=/a:b@$TMP/plug" >"$TMP/rerun.log" 2>&1
check "a second run keeps finished outputs" $?

cmp judge --out "$TMP/o" --claude "$TMP/claude" >"$TMP/judge.log" 2>&1
check "judge exits 0" $?
[ "$(find "$TMP/o/verdicts" -name '*.json' | wc -l)" = "$cases" ]
check "judge writes one verdict per case" $?

cmp report --out "$TMP/o" >"$TMP/report.log" 2>&1
check "report exits 0" $?
grep -q "^| Hard-gate failures | $((cases * 2)) | 0 |$" "$TMP/o/report.md"
check "report counts the gate failures per condition" $?
grep -q "^| Ranked first | 0 | $cases |$" "$TMP/o/report.md"
check "report counts first places per condition" $?
grep -q "^| Mean score, outputs that passed | n/a | 4.00 |$" "$TMP/o/report.md"
check "report leaves failed outputs out of the mean score" $?

cmp run --out "$TMP/x" --claude "$TMP/claude" --condition "bad name" >/dev/null 2>&1
[ $? != 0 ]
check "run rejects a bad condition name" $?

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
