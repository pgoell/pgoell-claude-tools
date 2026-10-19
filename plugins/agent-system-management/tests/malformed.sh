# Malformed input in both readers: wrong-typed or non-finite fields in
# eval_metadata.json, grading.json, timing.json and the viewer's --benchmark
# file, a "</script>" in the viewer's embedded data, and files that cannot
# be read. Sourced by run.sh.

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
