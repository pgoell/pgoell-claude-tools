# generate_review.py --static on its own: which runs the viewer finds and
# their prompt, eval id and grading. Sourced by run.sh.

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
