# gate.sh with fake gh, git, curl
good() { rm -f "$FAKE/pr_state" "$FAKE/auto" "$FAKE/checks" "$L/task.notified"; : >"$STUB/screen"; echo CLOSED >"$FAKE/issue_state"; echo 5 >"$FAKE/prs"; printf -- '- [x] a Test: t1\n- [x] b Proof: t2\n' >"$FAKE/body"; echo src/app.py >"$FAKE/files"; echo abc1234 >"$FAKE/live"; : >"$FAKE/dirty"; rm -f "$FAKE/down"; }
gate() { PATH="$T/bin:$PATH" "$L/gate.sh" 7 2>&1; }
use() { printf '{"type":"assistant","message":{"usage":{"input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0}}}\nnot json\n' "$1" "$2" >"$proj/a.jsonl"; }
gateh() { HOME="$T/home" gate; }
test_gate() {
make_fakes
good; out=$(gate); ok "gate pass exit" $? 0
has "gate pass word" "$out" "GATE PASS"; has "gate lists opened issues" "$out" "#12 [bug]"; has "gate prints minutes" "$out" "minutes: 0"
hasnt "gate: no TELL line for plain files" "$out" "TELL HUMAN"
good; printf -- '- [x] a Test: t1\n- [ ] b\n' >"$FAKE/body"; out=$(gate); ok "gate fails on an open box" $? 1; has "open box named" "$out" "PR 5: 1 open boxes"
good; printf -- '- [x] a\n- [x] b\n' >"$FAKE/body"; out=$(gate); ok "gate fails on ticked boxes without a test" $? 1
has "no-test boxes named" "$out" "FAIL PR 5: 2 ticked boxes name no test"
good; printf -- '  - [X] a\n' >"$FAKE/body"; out=$(gate); has "gate fails on an indented [X] without a test" "$out" "FAIL PR 5: 1 ticked boxes name no test"
good; printf -- '- [x] a\n  Test: t1\n- [x] b\n' >"$FAKE/body"; out=$(gate); has "a Test: under the box counts, a box with none fails" "$out" "FAIL PR 5: 1 ticked boxes name no test"
good; printf -- '- [x] a docs line. Check: `mise run lint`\n- [x] b\n  Check: lint\n' >"$FAKE/body"; out=$(gate); ok "gate counts Check: as a box's proof" $? 0
good; echo 'no boxes here' >"$FAKE/body"; out=$(gate); ok "gate passes a body with no boxes" $? 0
good; printf -- '- [x] a Test: t1\n```\n- [x] example\n```\n' >"$FAKE/body"; out=$(gate); ok "gate skips a ticked box in a code block" $? 0
good; echo OPEN >"$FAKE/issue_state"; out=$(gate); has "gate fails on an open issue" "$out" "FAIL issue 7 open"
good; echo fff0000 >"$FAKE/live"; out=$(gate); has "gate fails when live is not the head" "$out" "FAIL live is fff0000, main is abc1234"
good; echo ' M x' >"$FAKE/dirty"; out=$(gate); has "gate fails on a dirty tree" "$out" "FAIL working tree dirty"
good; touch "$FAKE/down"; out=$(gate); has "gate fails when the app is down" "$out" "FAIL live app does not answer"
good; printf '.github/workflows/deploy.yml\nsrc/a.py\n' >"$FAKE/files"; out=$(gate); ok "machine file does not fail the gate" $? 0
has "gate tells the human" "$out" "TELL HUMAN: PR 5 touched .github/workflows/deploy.yml"
hasnt "gate: no handover line without a transcript" "$out" "HAND OVER NOW"
has "gate: unknown context without a transcript" "$out" "orchestrator context: unknown tokens"
# a task that ended with HELD: its PR waits for the owner's review
held() { good; echo OPEN >"$FAKE/issue_state"; echo OPEN >"$FAKE/pr_state"; echo '{"enabledAt":"x"}' >"$FAKE/auto"; echo 'HELD #7: waits for the owner' >"$L/task.notified"; }
held; out=$(gate); ok "a held task passes the gate" $? 0; has "gate says GATE HELD" "$out" "GATE HELD"
hasnt "a held task is no GATE PASS" "$out" "GATE PASS"; has "gate names the held PR" "$out" "HELD PR 5: waits for the owner's review"
hasnt "a held PR is not failed as unmerged" "$out" "not merged"; hasnt "a held task's open issue is no failure" "$out" "FAIL issue 7 open"
held; rm "$L/task.notified"; printf 'report\nHELD #7: waits for the owner\n' >"$STUB/screen"; out=$(gate); has "gate reads HELD from the screen" "$out" "GATE HELD"
held; rm "$FAKE/auto"; out=$(gate); ok "a held PR without auto-merge fails" $? 1; has "gate names the missing auto-merge" "$out" "FAIL PR 5 held without auto-merge"
held; printf 'Test fail\nLint pending\n' >"$FAKE/checks"; out=$(gate); ok "a held PR with a red check fails" $? 1
has "gate names the red check" "$out" "FAIL PR 5 held with check Test fail"; has "gate names the running check" "$out" "FAIL PR 5 held with check Lint pending"
held; echo MERGED >"$FAKE/pr_state"; out=$(gate); ok "HELD with no open PR fails" $? 1; has "gate says no PR is held" "$out" "no PR of it is open"
good; echo OPEN >"$FAKE/pr_state"; out=$(gate); has "without HELD an open PR still fails" "$out" "FAIL PR 5 not merged"
good
proj="$T/home/.claude/projects/$(printf %s "$(cd "$L" && pwd -P)" | sed 's/[^A-Za-z0-9]/-/g')"; mkdir -p "$proj"
good; use 10 90000; out=$(gateh); ok "gate passes under 120k" $? 0; has "gate prints the context" "$out" "orchestrator context: 90010 tokens"
hasnt "no handover under 120k" "$out" "HAND OVER"
good; use 10 130000; out=$(gateh); ok "context past 120k does not fail the gate" $? 0; has "gate says hand over past 120k" "$out" "HAND OVER: past 120k"
hasnt "no hard handover under 150k" "$out" "HAND OVER NOW"
good; use 10 200000; out=$(gateh); ok "context does not fail the gate" $? 0; has "gate says hand over past 150k" "$out" "HAND OVER NOW: past 150k"
has "gate still passes past 150k" "$out" "GATE PASS"
rm -rf "$T/home"
}
