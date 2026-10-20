# The only file besides models.env that may name models: it searches for them.
# test_models: the shipped models, the refusals of next.sh and start.sh, and
# that no other file names a model.
test_models() {
local models d hits bad
models=$(cat "$L/models.env")
d=$(. "$skill/assets/models.env"; echo "$HARNESS $CLAUDE_ORCH_MODEL $CLAUDE_IMPL_MODEL $CLAUDE_CODER_MODEL $CLAUDE_REVIEW_MODEL $CLAUDE_ADVISOR_MODEL $REVIEW_NOT")
ok "models.env ships the issue's defaults" "$d" "CLAUDE opus opus haiku opus fable haiku"

# a reason is a comment with "empty" above the value, in the same block
bad=$(awk '
  /^$/ { reason = 0; next }
  /^#/ { if (/empty/) reason = 1; next }
  /^CODEX_[A-Z]+_MODEL=/ { if ($0 !~ /=$/ || !reason) print $0 }
' "$skill/assets/models.env")
ok "every empty Codex value has a reason" "$bad" ""

# next.sh refuses a review model that matches REVIEW_NOT, and sends nothing
refuse_reviewer() {
  sed -i "s/^CLAUDE_REVIEW_MODEL=.*/CLAUDE_REVIEW_MODEL=$2/" "$L/models.env"
  echo idle >"$STUB/status"; rm -f "$STUB/sent"
  out=$("$L/next.sh" --force "t" 2>&1); st=$?
  ok "$1" "$st" 3
  has "$1 names REVIEW_NOT" "$out" "matches REVIEW_NOT"
  ok "$1 sends nothing" "$(cat "$STUB/sent" 2>/dev/null)" ""
  printf '%s\n' "$models" >"$L/models.env"
}
refuse_reviewer "next refuses a haiku reviewer" haiku
refuse_reviewer "next refuses claude-haiku-5-5 as reviewer" claude-haiku-5-5

# a brief without the review placeholder (rule 3 overridden in rules.local.md) is refused, and nothing is sent
rules=$(cat "$L/rules.local.md")
printf '## 3\n3. Who codes. Subagents implement on {{CODER_MODEL}}. Review subagents run on the default model.\n' >>"$L/rules.local.md"
echo idle >"$STUB/status"; rm -f "$STUB/sent"
out=$("$L/next.sh" --force "t" 2>&1); ok "next refuses a brief without the model placeholders" $? 3
has "next names the missing placeholder" "$out" "{{REVIEW_MODEL}}"
ok "nothing sent for a brief without the placeholders" "$(cat "$STUB/sent" 2>/dev/null)" ""
printf '%s\n' "$rules" >"$L/rules.local.md"

sed -i 's/^CLAUDE_CODER_MODEL=.*/CLAUDE_CODER_MODEL=/' "$L/models.env"
echo idle >"$STUB/status"; rm -f "$STUB/sent"
out=$("$L/next.sh" --force "t" 2>&1); ok "next refuses an empty coder model" $? 3
has "next names CLAUDE_CODER_MODEL" "$out" "CLAUDE_CODER_MODEL is empty"
ok "nothing sent for an empty coder model" "$(cat "$STUB/sent" 2>/dev/null)" ""
printf '%s\n' "$models" >"$L/models.env"

# a folder without models.env: next.sh and start.sh refuse, lib.sh still loads
mv "$L/models.env" "$T/models.env.aside"
echo idle >"$STUB/status"; rm -f "$STUB/sent"
out=$("$L/next.sh" --force "t" 2>&1); ok "next refuses without models.env" $? 3
has "next says no models.env" "$out" "no models.env"
ok "nothing sent without models.env" "$(cat "$STUB/sent" 2>/dev/null)" ""
out=$("$L/start.sh" orch2 "$L" "o" "$T/msg" 2>&1); ok "start refuses without models.env" $? 3
has "start says no models.env" "$out" "no models.env"
out=$(bash -c "ISSUE_LOOP_DIR='$L' . '$skill/assets/lib.sh' && echo ok" 2>&1); ok "lib.sh loads without models.env" "$out" "ok"
mv "$T/models.env.aside" "$L/models.env"

# only models.env and this file name a model
hits=$(grep -rliE 'opus|sonnet|haiku|fable|claude-[a-z]+-[0-9]' --exclude=models.env --exclude=test-models.sh "$here/..")
ok "no file outside models.env names a model" "$hits" ""
hits=$(grep -rliF 'default model' --exclude=test-models.sh "$here/..")
ok "no file says default model" "$hits" ""
has "README names models.env" "$(cat "$here/../README.md")" "models.env"

# the herdr driver puts the model flags on the agent start command line
mkdir -p "$T/bin2"
cat >"$T/bin2/herdr" <<HERD
#!/bin/bash
case "\$1 \$2" in
"tab create") echo '{"result":{"pane_id":"p9"}}' ;;
"agent start") echo "\$*" >"$T/herdr_args" ;;
esac
HERD
chmod +x "$T/bin2/herdr"
(
  PATH="$T/bin2:$PATH"; LOOP_SLEEP_SCALE=0; nap() { :; }
  . "$skill/assets/driver-herdr.sh"
  SESSION_MODEL=m1 ADVISOR_MODEL=a1 PERMISSION_MODE=auto
  drv_start s1 "$T" lbl >/dev/null
)
has "herdr driver passes --model and --advisor" "$(cat "$T/herdr_args")" "--permission-mode auto --model m1 --advisor a1"
(
  PATH="$T/bin2:$PATH"; LOOP_SLEEP_SCALE=0; nap() { :; }
  . "$skill/assets/driver-herdr.sh"
  SESSION_MODEL= ADVISOR_MODEL= PERMISSION_MODE=auto
  drv_start s1 "$T" lbl >/dev/null
)
args=$(cat "$T/herdr_args")
ok "herdr driver passes no flag for empty models" "${args##*--permission-mode}" " auto"
hasnt "no --model for an empty model" "$args" "--model"
hasnt "no --advisor for an empty advisor" "$args" "--advisor"
}
