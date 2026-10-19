#!/bin/bash
# usage: tests/run.sh
# Runs creating-skills' aggregate_benchmark.py and eval-viewer/generate_review.py
# (--static) against fixture iteration folders: the flat layout SKILL.md
# describes, the run-<n> layout, a mix of both, an ungraded run, a stray
# run-* entry, config order, timing and token sources, evals with and
# without eval_metadata.json, an eval_id that is not an int (null, string,
# missing, true, in a folder with or without an id), eval_metadata.json that
# is not an object, unique eval ids (a taken folder id, a duplicate metadata
# id, an eval with no runs, a run outside any eval, two iterations),
# wrong-typed or non-finite fields in eval_metadata.json, grading.json,
# timing.json and the viewer's --benchmark file, files that cannot be read,
# a "</script>" in the viewer's embedded data, and the dash shown for a missing delta (main() with the delta taken out). AGG
# and VIEWER override the script paths (to
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
  if [ -n "$3" ]; then
    mfix "$1" "$2" "{\"eval_id\":$3,\"prompt\":\"P\"}"
  else
    mfix "$1" "$2" '{"prompt":"P"}'
  fi
}
# mfix <iteration> <folder> <text>: as meta, with eval_metadata.json holding
# that text ("" writes no eval_metadata.json)
mfix() {
  local e="$T/$1/$2"
  mkdir -p "$e/with_skill/outputs"
  echo x >"$e/with_skill/outputs/x.txt"
  [ -n "$3" ] && echo "$3" >"$e/eval_metadata.json"
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

# bad eval_id in a folder with no id: one past the largest id in use
meta idname eval-5-a 5
meta idname eval-x-b '"9"'
ok "no folder id: benchmark next free id" "$(bids idname)" "5,6 5,6"
ok "no folder id: viewer next free id" "$(vids idname)" 5,6

# non-object metadata (#191): eval_metadata.json that is valid JSON but not
# an object warns and counts as no metadata, so the folder id holds
meta nonobj eval-1-a 1
mfix nonobj eval-3-b '[]'
mfix nonobj eval-4-c '"x"'
mfix nonobj eval-5-d 1
out=$(run nonobj)
hasnt "non-object metadata: benchmark no crash" "$out" Traceback
has "non-object metadata: benchmark warns" "$out" "Warning: $T/nonobj/eval-3-b/eval_metadata.json: not a JSON object"
ok "non-object metadata: benchmark folder ids" "$(bids nonobj)" "1,3,4,5 1,3,4,5"
out=$(view nonobj)
hasnt "non-object metadata: viewer no crash" "$out" Traceback
ok "non-object metadata: viewer folder ids" "$(vids nonobj)" 1,3,4,5

# unique id (#192): no two evals share an id. An int metadata id first (the
# first eval in folder order keeps a duplicate), then the folder id if free,
# else one past the largest id in use
meta uniq eval-1-a 1
mfix uniq eval-x-b '{}'
ok "unique id: issue case benchmark" "$(bids uniq)" "1,2 1,2"
ok "unique id: issue case runs per config" "$(q uniq '.metadata.runs_per_configuration')" 1
ok "unique id: issue case viewer" "$(vids uniq)" 1,2
meta taken eval-1-a ""
meta taken eval-2-b 1
ok "unique id: folder id taken benchmark" "$(bids taken)" "1,2 2,1"
ok "unique id: folder id taken viewer" "$(vids taken)" 1,2
meta dup eval-1-a 3
meta dup eval-2-b 3
out=$(run dup)
has "unique id: duplicate warns" "$out" "Warning: $T/dup/eval-2-b: eval_id 3 is taken"
ok "unique id: duplicate benchmark" "$(bids dup)" "2,3 3,2"
ok "unique id: duplicate viewer" "$(vids dup)" 2,3
# viewer: a run in an eval-* folder with no eval_metadata.json takes its id
meta vuniq eval-1-foo 1
mfix vuniq eval-2-bar ""
ok "unique id: viewer eval without metadata" "$(vids vuniq)" 1,2
# an eval with no runs still holds its id, in the benchmark and the viewer
mkdir -p "$T/norun/eval-1-a"
echo '{"eval_id":7}' >"$T/norun/eval-1-a/eval_metadata.json"
meta norun eval-7-b ""
ok "unique id: eval without runs benchmark" "$(bids norun)" "8 8"
ok "unique id: eval without runs viewer" "$(vids norun)" 8
# a run outside any eval-* folder keeps its own metadata id and holds no id
# from the evals
mfix outside eval-3-a ""
mkdir -p "$T/outside/extra/with_skill/run-1/outputs"
echo x >"$T/outside/extra/with_skill/run-1/outputs/x.txt"
grade "$T/outside/extra/with_skill/run-1" 1.0
echo '{"eval_id":3}' >"$T/outside/extra/eval_metadata.json"
ok "unique id: run outside an eval" "$(bids outside) $(vids outside)" "3 3 3,3"
# ids are unique per folder of evals: two iterations may share an id
for i in 1 2; do mfix iters "iteration-$i/eval-0-a" '{"eval_id":0,"prompt":"p"}'; done
out=$(view iters)
hasnt "unique id: per iteration no warning" "$out" "Warning"
ok "unique id: per iteration viewer" "$(vq iters '[.runs[].eval_id]|join(",")')" 0,0
# a run-less eval beside a run's eval counts when the viewer runs a level up
mfix deep iteration-1/eval-1-a ""
mkdir -p "$T/deep/iteration-1/eval-2-b"
echo '{"eval_id":1,"prompt":"p"}' >"$T/deep/iteration-1/eval-2-b/eval_metadata.json"
view deep >/dev/null
ok "unique id: run-less sibling below workspace" "$(vq deep '[.runs[].eval_id]|join(",")')" 2

# metadata fields: a non-string eval_name or prompt is dropped
mfix mfields eval-1-a '{"eval_id":1,"eval_name":5,"prompt":7}'
out=$(run mfields)
has "metadata fields: eval_name warns" "$out" "eval_name is not a string"
ok "metadata fields: eval_name" "$(q mfields '.runs[0].eval_name')" null
view mfields >/dev/null
ok "metadata fields: viewer prompt" "$(vq mfields '.runs[0].prompt')" "(No prompt found)"

# gfix <iteration> <grading.json text>: eval-1-foo with one with_skill run
# (outputs/ and that grading.json); runs the benchmark and the viewer and
# keeps their output in $out
gfix() {
  local e
  e=$(eval_dir "$1")
  mkdir -p "$e/with_skill/outputs"
  echo x >"$e/with_skill/outputs/x.txt"
  echo "$2" >"$e/with_skill/grading.json"
  out=$(run "$1"; view "$1")
}
# grading fields: a wrong-typed field takes its default, never a crash
gfix gnon '[]'
hasnt "grading fields: non-object no crash" "$out" Traceback
ok "grading fields: non-object run skipped" "$(q gnon '.runs|length')" 0
ok "grading fields: non-object viewer no grades" "$(vq gnon '.runs[0].grading')" null
gfix gsum '{"summary":"x"}'
hasnt "grading fields: summary no crash" "$out" Traceback
ok "grading fields: summary pass rate" "$(q gsum '.runs[0].result.pass_rate == 0')" true
ok "grading fields: summary viewer" "$(vq gsum '.runs[0].grading.summary|tojson')" "{}"
gfix grate '{"summary":{"pass_rate":"x","passed":1}}'
hasnt "grading fields: pass_rate no crash" "$out" Traceback
has "grading fields: pass_rate warns" "$out" "summary.pass_rate is not a number"
ok "grading fields: pass_rate" "$(q grate '.runs[0].result.pass_rate == 0')" true
ok "grading fields: pass_rate viewer" "$(vq grate '.runs[0].grading.summary|tojson')" '{"pass_rate":0,"passed":1}'
gfix gexp '{"expectations":5}'
hasnt "grading fields: expectations no crash" "$out" Traceback
ok "grading fields: expectations" "$(q gexp '.runs[0].expectations|tojson')" "[]"
ok "grading fields: expectations viewer" "$(vq gexp '.runs[0].grading.expectations|tojson')" "[]"
gfix gitem '{"expectations":[1,{"text":"t","passed":true}]}'
hasnt "grading fields: expectation item no crash" "$out" Traceback
ok "grading fields: expectation item" "$(q gitem '[.runs[0].expectations[].text]|join(",")')" t
ok "grading fields: expectation item viewer" "$(vq gitem '[.runs[0].grading.expectations[].text]|join(",")')" t
gfix gtime '{"timing":"x"}'
hasnt "grading fields: timing no crash" "$out" Traceback
ok "grading fields: timing" "$(q gtime '.runs[0].result.time_seconds == 0')" true
gfix gmet '{"execution_metrics":[]}'
hasnt "grading fields: execution_metrics no crash" "$out" Traceback
ok "grading fields: execution_metrics" "$(q gmet '.runs[0].result.tool_calls')" 0
gfix gcalls '{"execution_metrics":{"total_tool_calls":"x"}}'
ok "grading fields: total_tool_calls" "$(q gcalls '.runs[0].result.tool_calls')" 0
gfix gnotes '{"user_notes_summary":[]}'
hasnt "grading fields: user_notes_summary no crash" "$out" Traceback
ok "grading fields: user_notes_summary" "$(q gnotes '.runs[0].notes|length')" 0
gfix gunc '{"user_notes_summary":{"uncertainties":"abc","workarounds":["w"]}}'
ok "grading fields: uncertainties" "$(q gunc '.runs[0].notes|join(",")')" w
# a number must be finite: an int too big for a float, or NaN, is ignored
big=1$(printf '0%.0s' {1..400})
gfix ghuge "{\"summary\":{\"pass_rate\":$big}}"
hasnt "grading fields: huge pass_rate no crash" "$out" Traceback
ok "grading fields: huge pass_rate" "$(q ghuge '.runs[0].result.pass_rate == 0')" true
gfix gnan '{"summary":{"pass_rate":NaN}}'
ok "grading fields: NaN pass_rate" "$(grep -c NaN "$T/gnan/benchmark.json") $(q gnan '.runs[0].result.pass_rate == 0')" "0 true"
ok "grading fields: NaN pass_rate viewer" "$(vq gnan '.runs[0].grading.summary.pass_rate')" 0

# script tag: a "</script>" in embedded data cannot end the page's script
gfix stag '{"expectations":[{"text":"a </script><b>","passed":true}]}'
ok "script tag: escaped" "$(grep -c '</script><b>' "$T/stag.html") $(vq stag '.runs[0].grading.expectations[0].text')" "0 a </script><b>"
gfix scom '{"expectations":[{"text":"<!--<script>","passed":true}]}'
ok "script tag: comment escaped" "$(grep -c '<!--<script>' "$T/scom.html") $(vq scom '.runs[0].grading.expectations[0].text')" "0 <!--<script>"

# tfix <iteration> <timing.json text>: a graded run with that timing.json
tfix() {
  local e
  e=$(eval_dir "$1")
  grade "$e/with_skill" 1.0
  echo "$2" >"$e/with_skill/timing.json"
  out=$(run "$1")
}
# timing fields: a wrong-typed field is ignored, never a crash
tfix tnon '[]'
hasnt "timing fields: non-object no crash" "$out" Traceback
has "timing fields: non-object warns" "$out" "timing.json: not a JSON object"
ok "timing fields: non-object tokens" "$(q tnon '.runs[0].result.tokens')" 0
tfix ttok '{"total_tokens":"x","total_duration_seconds":2}'
hasnt "timing fields: total_tokens no crash" "$out" Traceback
ok "timing fields: total_tokens" "$(q ttok '.runs[0].result.tokens')" 0
tfix tms '{"duration_ms":"x"}'
hasnt "timing fields: duration_ms no crash" "$out" Traceback
ok "timing fields: duration_ms" "$(q tms '.runs[0].result.time_seconds == 0')" true
tfix thuge "{\"duration_ms\":$big}"
hasnt "timing fields: huge duration_ms no crash" "$out" Traceback
ok "timing fields: huge duration_ms" "$(q thuge '.runs[0].result.time_seconds == 0')" true

# bview <iteration> <benchmark.json text>: one viewer run, with --benchmark
# pointing at that benchmark.json; keeps the output in $out
bview() {
  local e
  e=$(eval_dir "$1")
  mkdir -p "$e/with_skill/outputs"
  echo x >"$e/with_skill/outputs/x.txt"
  echo "$2" >"$T/$1-benchmark.json"
  out=$(python3 "$viewer" "$T/$1" --static "$T/$1.html" --skill-name x --benchmark "$T/$1-benchmark.json" 2>&1)
}
# benchmark fields: the Benchmark tab gets wrong-typed fields dropped or
# defaulted, and no tab for a non-object file
bview bnon '"x"'
has "benchmark fields: non-object warns" "$out" "bnon-benchmark.json: not a JSON object"
ok "benchmark fields: non-object no tab" "$(vq bnon '.benchmark')" null
bview btop '{"metadata":{"evals_run":"x","skill_name":"s"},"runs":5,"notes":3,"run_summary":{"with_skill":{"pass_rate":{"mean":"x","stddev":0},"time_seconds":{"mean":1,"stddev":0}},"old_skill":5,"delta":7}}'
has "benchmark fields: evals_run warns" "$out" "metadata.evals_run is not a list"
ok "benchmark fields: evals_run" "$(vq btop '.benchmark.metadata|tojson')" '{"skill_name":"s"}'
ok "benchmark fields: runs" "$(vq btop '.benchmark.runs|tojson')" "[]"
ok "benchmark fields: notes" "$(vq btop '.benchmark.notes|tojson')" "[]"
ok "benchmark fields: stat mean" "$(vq btop '.benchmark.run_summary.with_skill|keys|join(",")')" time_seconds
ok "benchmark fields: config" "$(vq btop '.benchmark.run_summary|keys|join(",")')" delta,with_skill
ok "benchmark fields: delta" "$(vq btop '.benchmark.run_summary.delta|tojson')" "{}"
bview bruns '{"runs":[1,{"configuration":5},{"configuration":"with_skill","result":"x"},{"configuration":"with_skill","result":{"pass_rate":"x","passed":1},"expectations":[null,{"text":"t"}]},{"configuration":"with_skill","expectations":3}],"notes":["n",4]}'
has "benchmark fields: run item warns" "$out" "runs item is not an object"
ok "benchmark fields: bad runs dropped" "$(vq bruns '.benchmark.runs|length')" 3
ok "benchmark fields: result" "$(vq bruns '.benchmark.runs[0].result|tojson')" "{}"
ok "benchmark fields: result numbers" "$(vq bruns '.benchmark.runs[1].result|tojson')" '{"passed":1}'
ok "benchmark fields: expectation items" "$(vq bruns '.benchmark.runs[1].expectations|tojson')" '[{"text":"t"}]'
ok "benchmark fields: expectations" "$(vq bruns '.benchmark.runs[2].expectations|tojson')" "[]"
ok "benchmark fields: note items" "$(vq bruns '.benchmark.notes|join(",")')" n

# unreadable: a grading.json or eval_metadata.json that is a directory warns
E=$(eval_dir unread)
mkdir -p "$E/with_skill/outputs" "$E/with_skill/grading.json"
echo x >"$E/with_skill/outputs/x.txt"
mfix unread eval-3-u ""
mkdir -p "$T/unread/eval-3-u/eval_metadata.json"
out=$(run unread)
hasnt "unreadable: benchmark no crash" "$out" Traceback
has "unreadable: benchmark grading warns" "$out" "Warning: $E/with_skill/grading.json: cannot read"
has "unreadable: benchmark metadata warns" "$out" "Warning: $T/unread/eval-3-u/eval_metadata.json: cannot read"
ok "unreadable: benchmark ids" "$(q unread '[.runs[].eval_id]|join(",")')" 3
out=$(view unread)
has "unreadable: viewer grading warns" "$out" "Warning: $E/with_skill/grading.json: cannot read"
has "unreadable: viewer metadata warns" "$out" "Warning: $T/unread/eval-3-u/eval_metadata.json: cannot read"

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
