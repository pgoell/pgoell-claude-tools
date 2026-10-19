# Shared helpers and fixtures, sourced by run.sh before the area files.
# Uses run.sh's $T, $agg, $viewer and the pass/fail counters.
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
