#!/bin/bash
# usage: tests/run.sh
# Runs creating-skills' aggregate_benchmark.py and eval-viewer/generate_review.py
# (--static) against fixture iteration folders: the flat layout SKILL.md
# describes, the run-<n> layout, a mix of both, an ungraded run, a stray
# run-* entry, config order, timing and token sources, and evals with and
# without eval_metadata.json. AGG and VIEWER override the script paths (to
# run the cases against another copy). No session, no network. Needs bash,
# python3, jq.
set -u
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
agg="${AGG:-$here/../skills/creating-skills/scripts/aggregate_benchmark.py}"
viewer="${VIEWER:-$here/../skills/creating-skills/eval-viewer/generate_review.py}"
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
  echo '{"eval_id":1,"eval_name":"foo","prompt":"PROMPTX","assertions":[]}' >"$e/eval_metadata.json"
  echo "$e"
}
run() { python3 "$agg" "$T/$1" --skill-name x 2>&1; }
q() { jq -r "$2" "$T/$1/benchmark.json"; }
# view <iteration>: write the static viewer page, print the run's output
view() { python3 "$viewer" "$T/$1" --static "$T/$1.html" --skill-name x 2>&1; }
# vq <iteration> <jq>: query the JSON the viewer embeds in its page
vq() {
  python3 -c 'import sys
s = open(sys.argv[1]).read()
k = "const EMBEDDED_DATA = "
a = s.index(k) + len(k)
print(s[a:s.index(";\n", a)])' "$T/$1.html" | jq -r "$2"
}

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

# runs per config: the most runs found for any (eval, config) pair
ok "runs per config: run-n" "$(q repeat '.metadata.runs_per_configuration')" 2
ok "runs per config: flat" "$(q flat '.metadata.runs_per_configuration')" 1

# eval name: from eval_metadata.json
ok "eval name: flat" "$(q flat '[.runs[].eval_name]|unique|join(",")')" foo
ok "eval name: run-n" "$(q repeat '[.runs[].eval_name]|unique|join(",")')" foo

# run-notes: a run-* entry that is not run-<digits> is skipped with a warning
E=$(eval_dir notes)
grade "$E/with_skill/run-1" 1.0
mkdir -p "$E/with_skill/run-notes"
echo x >"$E/with_skill/run-log.txt"
out=$(run notes)
has "run-notes: warns on folder" "$out" "Warning: skipping $E/with_skill/run-notes: not a run-<n> folder"
has "run-notes: warns on file" "$out" "Warning: skipping $E/with_skill/run-log.txt: not a run-<n> folder"
ok "run-notes: one run" "$(q notes '.runs|length' 2>&1)" 1

# config order: with_skill first, so the delta is with_skill minus old_skill
E=$(eval_dir order)
grade "$E/with_skill" 1.0
grade "$E/old_skill" 0.0
run order >/dev/null
ok "config order: delta sign" "$(q order '.run_summary.delta.pass_rate')" +1.00
ok "config order: with_skill first" "$(q order '.run_summary|keys_unsorted[0]')" with_skill

# duration_ms: timing.json with only duration_ms gives the time
E=$(eval_dir durms)
grade "$E/with_skill" 1.0
echo '{"duration_ms":4500}' >"$E/with_skill/timing.json"
run durms >/dev/null
ok "duration_ms: time" "$(q durms '.runs[0].result.time_seconds')" 4.5

# tokens: from timing.json even when grading.json has timing, never output_chars
E=$(eval_dir tokens)
mkdir -p "$E/with_skill" "$E/without_skill"
g='{"summary":{"pass_rate":1.0,"passed":1,"failed":0,"total":1},"expectations":[],"timing":{"total_duration_seconds":3},"execution_metrics":{"output_chars":999}}'
echo "$g" >"$E/with_skill/grading.json"
echo "$g" >"$E/without_skill/grading.json"
echo '{"total_tokens":700,"total_duration_seconds":9}' >"$E/with_skill/timing.json"
run tokens >/dev/null
ok "tokens: from timing.json" "$(q tokens '.runs[]|select(.configuration=="with_skill").result.tokens')" 700
ok "tokens: grading.json time wins" "$(q tokens '.runs[]|select(.configuration=="with_skill").result.time_seconds')" 3
ok "tokens: 0 without timing.json" "$(q tokens '.runs[]|select(.configuration=="without_skill").result.tokens')" 0

# viewer run-n prompt: run-<n> runs find eval_metadata.json in the eval dir
E=$(eval_dir vrep)
for n in 1 2; do
  mkdir -p "$E/with_skill/run-$n/outputs"
  echo x >"$E/with_skill/run-$n/outputs/x.txt"
  grade "$E/with_skill/run-$n" 1.0
done
view vrep >/dev/null
ok "viewer run-n prompt: prompt" "$(vq vrep '[.runs[].prompt]|unique|join(",")')" PROMPTX
ok "viewer run-n prompt: eval id" "$(vq vrep '[.runs[].eval_id]|unique|join(",")')" 1
ok "viewer run-n prompt: run id" "$(vq vrep '.runs[0].id')" eval-1-foo-with_skill-run-1

# viewer mixed: outputs/ + grading.json and run-1/ in one config: run-1 only
E=$(eval_dir vmixed)
mkdir -p "$E/with_skill/outputs" "$E/with_skill/run-1/outputs"
echo x >"$E/with_skill/outputs/x.txt"
echo x >"$E/with_skill/run-1/outputs/x.txt"
grade "$E/with_skill" 0.0
grade "$E/with_skill/run-1" 1.0
view vmixed >/dev/null
ok "viewer mixed: run-1 only" "$(vq vmixed '[.runs[].id]|join(",")')" eval-1-foo-with_skill-run-1

# viewer grading: a run without its own grading.json shows none
E=$(eval_dir vgrade)
mkdir -p "$E/with_skill/run-1/outputs"
echo x >"$E/with_skill/run-1/outputs/x.txt"
grade "$E/with_skill" 1.0
view vgrade >/dev/null
ok "viewer grading: null" "$(vq vgrade '.runs[0].grading')" null

# viewer no metadata: an eval without eval_metadata.json beside one with it
E=$(eval_dir vnometa)
mkdir -p "$E/with_skill/outputs" "$T/vnometa/eval-2-bar/with_skill/outputs"
echo x >"$E/with_skill/outputs/x.txt"
echo x >"$T/vnometa/eval-2-bar/with_skill/outputs/x.txt"
out=$(view vnometa)
hasnt "viewer no metadata: no crash" "$out" "Traceback"
ok "viewer no metadata: both shown" "$(vq vnometa '[.runs[].id]|join(",")' 2>&1)" eval-1-foo-with_skill,eval-2-bar-with_skill

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
