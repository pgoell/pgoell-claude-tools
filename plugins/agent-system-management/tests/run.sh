#!/bin/bash
# usage: tests/run.sh
# Runs creating-skills' aggregate_benchmark.py and eval-viewer/generate_review.py
# (--static) against fixture iteration folders: the flat layout
# skills/creating-skills/references/running-evals.md describes, the run-<n> layout, a mix of both, an ungraded run, a stray
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
# The cases sit in one file per area beside this one (benchmark.sh,
# viewer.sh, eval-ids.sh, malformed.sh), with shared helpers in lib.sh.
set -u
export PYTHONDONTWRITEBYTECODE=1
here=$(cd "$(dirname "$0")" && pwd)
agg="${AGG:-$here/../skills/creating-skills/scripts/aggregate_benchmark.py}"
viewer="${VIEWER:-$here/../skills/creating-skills/eval-viewer/generate_review.py}"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0

source "$here/lib.sh"
source "$here/benchmark.sh"
source "$here/viewer.sh"
source "$here/eval-ids.sh"
source "$here/malformed.sh"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
