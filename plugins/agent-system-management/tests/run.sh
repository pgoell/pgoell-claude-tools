#!/bin/bash
# usage: tests/run.sh
# Runs creating-skills' aggregate_benchmark.py against fixture iteration
# folders: the flat layout SKILL.md describes, the run-<n> layout, a mix of
# both, and an ungraded run. No session, no network. Needs bash, python3, jq.
set -u
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
agg="$here/../skills/creating-skills/scripts/aggregate_benchmark.py"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got '$2', want '$3'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: no '$3' in: $2"; fi; }
hasnt() { if grep -qF -- "$3" <<<"$2"; then fail=$((fail + 1)); echo "FAIL $1: found '$3'"; else pass=$((pass + 1)); fi; }

# grade <dir> <pass_rate>: write a grading.json with one expectation
grade() {
  mkdir -p "$1"
  local p=0
  [ "$2" = 1.0 ] && p=1
  printf '{"summary":{"pass_rate":%s,"passed":%s,"failed":%s,"total":1},"expectations":[{"text":"t","passed":%s,"evidence":"e"}]}\n' \
    "$2" "$p" "$((1 - p))" "$([ "$p" = 1 ] && echo true || echo false)" >"$1/grading.json"
}
# eval_dir <iteration>: make eval-1-foo with its metadata, print its path
eval_dir() {
  local e="$T/$1/eval-1-foo"
  mkdir -p "$e"
  echo '{"eval_id":1,"eval_name":"foo","prompt":"p","assertions":[]}' >"$e/eval_metadata.json"
  echo "$e"
}
run() { python3 "$agg" "$T/$1" --skill-name x 2>&1; }
q() { jq -r "$2" "$T/$1/benchmark.json"; }

# flat layout: grading.json and outputs/ straight in the config folder
E=$(eval_dir flat)
mkdir -p "$E/with_skill/outputs" "$E/without_skill/outputs"
echo x >"$E/with_skill/outputs/x.txt"
grade "$E/with_skill" 1.0
grade "$E/without_skill" 0.0
run flat >/dev/null
ok "flat layout: one with_skill run" "$(q flat '[.runs[]|select(.configuration=="with_skill")]|length')" 1
ok "flat layout: one without_skill run" "$(q flat '[.runs[]|select(.configuration=="without_skill")]|length')" 1
ok "flat layout: eval id 1" "$(q flat '.metadata.evals_run|join(",")')" 1
ok "flat layout: with_skill pass rate" "$(q flat '.run_summary.with_skill.pass_rate.mean == 1')" true
ok "flat layout: run number 1" "$(q flat '.runs[0].run_number')" 1

# flat timing: time and tokens from timing.json beside grading.json
E=$(eval_dir flattime)
mkdir -p "$E/with_skill/outputs"
grade "$E/with_skill" 1.0
echo '{"total_tokens":500,"total_duration_seconds":12.5}' >"$E/with_skill/timing.json"
run flattime >/dev/null
ok "flat timing: time" "$(q flattime '.runs[0].result.time_seconds')" 12.5
ok "flat timing: tokens" "$(q flattime '.runs[0].result.tokens')" 500

# run-<n> layout: one folder per repeat
E=$(eval_dir repeat)
grade "$E/with_skill/run-1" 1.0
grade "$E/with_skill/run-2" 0.0
run repeat >/dev/null
ok "run-n layout: two runs" "$(q repeat '[.runs[]|select(.configuration=="with_skill")]|length')" 2
ok "run-n layout: run numbers" "$(q repeat '[.runs[].run_number]|sort|join(",")')" 1,2

# mixed: run-* folders win over a grading.json in the config folder
E=$(eval_dir mixed)
grade "$E/with_skill/run-1" 1.0
grade "$E/with_skill" 0.0
run mixed >/dev/null
ok "mixed: run-* only" "$(q mixed '[.runs[]|select(.configuration=="with_skill")]|length')" 1
ok "mixed: the run-1 grade" "$(q mixed '.runs[0].result.pass_rate == 1')" true

# ungraded: outputs/ with no grading.json warns, inputs/ stays quiet
E=$(eval_dir ungraded)
mkdir -p "$E/with_skill/outputs" "$E/inputs"
echo x >"$E/with_skill/outputs/x.txt"
out=$(run ungraded)
has "ungraded warn: warns" "$out" "grading.json not found"
has "ungraded warn: names with_skill" "$out" "with_skill"
hasnt "ungraded warn: quiet on inputs" "$out" "inputs"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
