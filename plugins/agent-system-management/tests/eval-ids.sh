# Eval ids in both readers: an eval_id that is not an int, metadata that is
# not an object, and ids that stay unique. Sourced by run.sh.

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
