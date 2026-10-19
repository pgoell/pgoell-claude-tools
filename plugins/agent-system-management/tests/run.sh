#!/bin/bash
# usage: tests/run.sh
# Runs creating-skills' aggregate_benchmark.py and eval-viewer/generate_review.py
# (--static) against fixture iteration folders: the flat layout SKILL.md
# describes, the run-<n> layout, a mix of both, an ungraded run, a stray
# run-* entry, config order, timing and token sources, evals with and
# without eval_metadata.json, an eval_id that is not an int (null, string,
# missing, true, in a folder with or without an id), and the dash shown for
# a missing delta (main() with the delta taken out). AGG and VIEWER override the script paths (to
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

# zero timing: a 0 in grading.json timing falls back to timing.json
E=$(eval_dir zerotime)
mkdir -p "$E/with_skill"
echo '{"summary":{"pass_rate":1.0,"passed":1,"failed":0,"total":1},"expectations":[],"timing":{"total_duration_seconds":0}}' >"$E/with_skill/grading.json"
echo '{"total_duration_seconds":12}' >"$E/with_skill/timing.json"
run zerotime >/dev/null
ok "zero timing: time" "$(q zerotime '.runs[0].result.time_seconds')" 12

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

# viewer run-notes: a run-* folder that is not run-<n> is not a run
E=$(eval_dir vnotes)
mkdir -p "$E/with_skill/run-notes/outputs" "$E/without_skill/outputs"
echo x >"$E/with_skill/run-notes/outputs/x.txt"
echo x >"$E/without_skill/outputs/x.txt"
grade "$E/with_skill/run-notes" 1.0
view vnotes >/dev/null
ok "viewer run-notes: not shown" "$(vq vnotes '[.runs[].id]|join(",")')" eval-1-foo-without_skill

# viewer no metadata: an eval without eval_metadata.json beside one with it
E=$(eval_dir vnometa)
mkdir -p "$E/with_skill/outputs" "$T/vnometa/eval-2-bar/with_skill/outputs"
echo x >"$E/with_skill/outputs/x.txt"
echo x >"$T/vnometa/eval-2-bar/with_skill/outputs/x.txt"
out=$(view vnometa)
hasnt "viewer no metadata: no crash" "$out" "Traceback"
ok "viewer no metadata: both shown" "$(vq vnometa '[.runs[].id]|join(",")' 2>&1)" eval-1-foo-with_skill,eval-2-bar-with_skill

# meta <iteration> <folder> <eval_id JSON>: an eval folder with a graded
# with_skill run, whose eval_metadata.json holds that eval_id ("" leaves
# the key out)
meta() {
  local e="$T/$1/$2"
  mkdir -p "$e/with_skill/outputs"
  echo x >"$e/with_skill/outputs/x.txt"
  if [ -n "$3" ]; then
    echo "{\"eval_id\":$3,\"prompt\":\"P\"}" >"$e/eval_metadata.json"
  else
    echo '{"prompt":"P"}' >"$e/eval_metadata.json"
  fi
  grade "$e/with_skill" 1.0
}
# bids <iteration>: benchmark.json's evals_run, then its runs' eval ids
bids() {
  run "$1" >/dev/null
  echo "$(q "$1" '.metadata.evals_run|join(",")' 2>&1)" \
    "$(q "$1" '[.runs[].eval_id|tostring]|join(",")' 2>&1)"
}
# vids <iteration>: the viewer's run eval ids, or its Traceback
vids() {
  local out
  out=$(view "$1")
  if grep -q Traceback <<<"$out"; then echo Traceback; else vq "$1" '[.runs[].eval_id|tostring]|join(",")'; fi
}

# bad eval_id: null, a string, a missing key or true beside an int id
# falls back to the folder id, in the benchmark and the viewer
meta idnull eval-1-a 1
meta idnull eval-7-b null
ok "null eval_id: benchmark folder id" "$(bids idnull)" "1,7 1,7"
ok "null eval_id: viewer folder id" "$(vids idnull)" 1,7
meta idstr eval-1-a 1
meta idstr eval-7-b '"9"'
ok "string eval_id: benchmark folder id" "$(bids idstr)" "1,7 1,7"
ok "string eval_id: viewer folder id" "$(vids idstr)" 1,7
meta idmiss eval-1-a 1
meta idmiss eval-5-b ""
ok "missing eval_id: benchmark folder id, not index" "$(bids idmiss)" "1,5 1,5"
ok "missing eval_id: viewer folder id" "$(vids idmiss)" 1,5
meta idbool eval-1-a 1
meta idbool eval-4-b true
ok "true eval_id: benchmark folder id" "$(bids idbool)" "1,4 1,4"
ok "true eval_id: viewer folder id" "$(vids idbool)" 1,4

# bad eval_id in a folder with no id: benchmark takes the index, viewer null
meta idname eval-5-a 5
meta idname eval-x-b '"9"'
ok "no folder id: benchmark index" "$(bids idname)" "1,5 5,1"
ok "no folder id: viewer null" "$(vids idname)" 5,null

# missing delta: benchmark.md and the summary show a dash. The script always
# writes a delta, so main() runs here with the delta taken out.
E=$(eval_dir dash)
grade "$E/with_skill" 1.0
out=$(python3 -c 'import importlib.util, sys
s = importlib.util.spec_from_file_location("agg", sys.argv[1])
m = importlib.util.module_from_spec(s)
s.loader.exec_module(m)
g = m.generate_benchmark
def nodelta(*a):
    b = g(*a)
    del b["run_summary"]["delta"]
    return b
m.generate_benchmark = nodelta
sys.argv = [sys.argv[1], sys.argv[2], "--skill-name", "x"]
m.main()' "$agg" "$T/dash" 2>&1)
has "missing delta: summary dash" "$out" "Delta:         "$'\xe2\x80\x94'
has "missing delta: benchmark.md dash" "$(cat "$T/dash/benchmark.md")" "| "$'\xe2\x80\x94'" |"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
