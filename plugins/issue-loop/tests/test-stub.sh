# The stub: the installed plugin, the pin in loop.env, a missing pin, no plugin,
# the task's plugin, the NEWER PLUGIN line, and a plugin script run directly.
# gate() and good() come from test-gate.sh and need test_gate to have run first.
regf="$T/claude/plugins/installed_plugins.json"
fake_version() { mkdir -p "$T/cache/$1/skills/running-the-loop/assets"; printf 'echo "%s"\n' "$2" >"$T/cache/$1/skills/running-the-loop/assets/gate.sh"; : >"$T/cache/$1/skills/running-the-loop/assets/rules.sh"; }
point_at() { printf '{"version":2,"plugins":{"issue-loop@pgoell-claude-tools":[{"scope":"user","installPath":"%s","version":"%s"}]}}\n' "$1" "$(basename "$1")" >"$regf"; }
test_stub() {
local good_reg good_env
good_reg=$(cat "$regf"); good_env=$(cat "$L/loop.env")
rm -f "$L/task.plugin"
fake_version 0.9.1 "fake 0.9.1"; fake_version 0.8.9 "fake 0.8.9"

point_at "$T/cache/0.9.1"; out=$("$L/gate.sh" 2>&1); ok "a stub runs the installed plugin (latest)" "$out" "fake 0.9.1"
printf '%s\nISSUE_LOOP_VERSION=0.8.9\n' "$good_env" >"$L/loop.env"
out=$("$L/gate.sh" 2>&1); ok "a pin runs that version's folder" "$out" "fake 0.8.9"
printf '%s\nISSUE_LOOP_VERSION=0.7.0\n' "$good_env" >"$L/loop.env"
out=$("$L/gate.sh" 2>&1); ok "a pin to a missing version exits 3" $? 3
has "a missing pin names its folder" "$out" "$T/cache/0.7.0"
hasnt "a missing pin runs nothing" "$out" "fake"
printf '%s\n' "$good_env" >"$L/loop.env"
printf '{"version":2,"plugins":{}}\n' >"$regf"
out=$("$L/gate.sh" 2>&1); ok "no installed issue-loop exits 3" $? 3
has "no installed issue-loop is named" "$out" "no installed issue-loop plugin in $regf"
printf '%s\n' "$good_reg" >"$regf"

# a folder from before 0.9.0 (gate.sh, no rules.sh) is refused, and nothing runs
mkdir -p "$T/cache/0.8.8/skills/running-the-loop/assets"; printf 'echo "fake 0.8.8"\n' >"$T/cache/0.8.8/skills/running-the-loop/assets/gate.sh"
printf '%s\nISSUE_LOOP_VERSION=0.8.8\n' "$good_env" >"$L/loop.env"
out=$("$L/gate.sh" 2>&1); ok "a pin to a folder from before 0.9.0 exits 3" $? 3
has "that refusal names the folder and the fix" "$out" "$T/cache/0.8.8 is from before 0.9.0 and cannot run a loop folder of stubs: pin 0.9.0 or later"
hasnt "a folder from before 0.9.0 runs nothing" "$out" "fake 0.8.8"
printf '%s\n' "$good_env" >"$L/loop.env"

# two entries: the newer version wins, whichever is listed first
printf '{"version":2,"plugins":{"issue-loop@proj":[{"scope":"project","installPath":"%s/cache/0.5.0","version":"0.5.0"}],"issue-loop@pgoell-claude-tools":[{"scope":"user","installPath":"%s/cache/0.9.0","version":"0.9.0"}]}}\n' "$T" "$T" >"$regf"
out=$(bash -c ". '$L/lib.sh' && echo \"\$ISSUE_LOOP_ROOT\"" 2>&1); ok "with two entries the stub runs the newer one" "$out" "$T/cache/0.9.0"
printf '%s\n' "$good_reg" >"$regf"

# sourced under set -eu: loads, and with no registry says so and stops
out=$(bash -c "set -eu; cd '$L'; . ./lib.sh; echo ok" 2>&1); ok "lib.sh sourced under set -eu loads" "$out" ok
out=$(CLAUDE_CONFIG_DIR="$T/none" bash -c "set -eu; cd '$L'; . ./lib.sh; echo ok" 2>&1); ok "sourced with no registry stops with 3" $? 3
has "sourced with no registry names the missing plugin" "$out" "no installed issue-loop plugin in $T/none/plugins/installed_plugins.json"

printf 'old rules\n' >"$L/rules.md"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses a folder with a full rules.md" $? 3
has "next names upgrade.sh" "$out" "upgrade.sh"
rm -f "$L/rules.md"
local_rules=$(cat "$L/rules.local.md")
printf '## 5.1\nfilled\n' >"$L/rules.local.md"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses an unanswered FILL" $? 3
has "next names the unanswered ## 1.1" "$out" "## 1.1"
printf '%s\n' "$local_rules" >"$L/rules.local.md"
printf '%s\n## nine\nbad\n' "$local_rules" >"$L/rules.local.md"
rm -f "$STUB/sent"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses a bad ## line in rules.local.md" $? 3
has "next names the bad ## line" "$out" "## nine"
ok "nothing sent for a bad ## line" "$(cat "$STUB/sent" 2>/dev/null)" ""
printf '%s\n' "$local_rules" >"$L/rules.local.md"

echo orch >"$L/orch-name"; echo idle >"$STUB/status"; rm -f "$STUB/sent"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next starts a task" $? 0
ok "task.plugin holds the plugin folder" "$(cat "$L/task.plugin")" "$T/cache/0.9.0"

fake_version 0.9.1 WRONG; point_at "$T/cache/0.9.1"
good; out=$(gate); ok "a newer plugin does not fail the gate" $? 0
has "gate names the newer plugin" "$out" "NEWER PLUGIN: issue-loop 0.9.1 is installed, this task ran 0.9.0. The next next.sh takes it up."
has "gate passes with a newer plugin" "$out" "GATE PASS"
hasnt "gate runs the task's plugin, not the newer one" "$out" "WRONG"
printf '%s\nISSUE_LOOP_VERSION=0.9.0\n' "$good_env" >"$L/loop.env"
good; out=$(gate); has "a pin names the hold" "$out" "ISSUE_LOOP_VERSION=0.9.0 in loop.env holds the loop back."
printf '%s\n' "$good_env" >"$L/loop.env"

fake_version 0.10.0 "fake 0.10.0"; point_at "$T/cache/0.10.0"
good; out=$(gate); has "sort -V counts 0.10.0 newer than 0.9.0" "$out" "NEWER PLUGIN: issue-loop 0.10.0 is installed"
point_at "$T/cache/0.8.9"
good; out=$(gate); hasnt "an older installed plugin prints no NEWER PLUGIN" "$out" "NEWER PLUGIN"

out=$(unset ISSUE_LOOP_DIR; bash "$skill/assets/gate.sh" 7 2>&1); ok "a plugin script run directly exits 2" $? 2
has "a direct run says through the stub" "$out" "through the stub"

printf '%s\n' "$good_reg" >"$regf"; printf '%s\n' "$good_env" >"$L/loop.env"

# the loop's lib.sh is a stub too: sourced, it loads the plugin's lib and sets S to the loop folder
out=$(bash -c ". '$L/lib.sh' && type drv_read >/dev/null && echo ok" 2>&1); ok "sourced lib.sh loads the plugin's lib" "$out" ok
out=$(bash -c ". '$L/lib.sh' && echo \"\$S\""); ok "sourced lib.sh sets S to the loop folder" "$out" "$(cd "$L" && pwd -P)"
}
