# aggregate_benchmark.py on its own: layouts, runs per config, eval names,
# config order, timing and token sources, the missing-delta dash. Sourced
# by run.sh.

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
