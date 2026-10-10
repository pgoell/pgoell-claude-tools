#!/bin/bash
# usage: tests/run.sh
# Runs the loop's script templates against a stub driver and fake gh, git and
# curl. No session, no network. Needs bash, jq, GNU date and timeout.
set -u
here=$(cd "$(dirname "$0")" && pwd)
skill="$here/../skills/running-the-loop"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got '$2', want '$3'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: no '$3' in: $2"; fi; }
hasnt() { if grep -qF -- "$3" <<<"$2"; then fail=$((fail + 1)); echo "FAIL $1: found '$3'"; else pass=$((pass + 1)); fi; }

# init.sh: copies templates, refuses a folder inside a checkout
L="$T/loop"
out=$("$skill/scripts/init.sh" "$L" 2>&1); ok "init exit" $? 0
hasnt "init prints no cp warning" "$out" "cp:"
for f in loop.env lib.sh next.sh wait.sh gate.sh start.sh notify.sh rules.md ledger.tsv driver-herdr.sh HANDOFF.md; do
  [ -f "$L/$f" ]; ok "init copies $f" $? 0
done
mkdir -p "$T/co" && git -C "$T/co" init -q
out=$("$skill/scripts/init.sh" "$T/co/a/loop" 2>&1); ok "init refuses a checkout" $? 1
[ -e "$T/co/a" ]; ok "a refused folder is not left behind" $? 1
echo keep >"$L/ledger.tsv"; "$skill/scripts/init.sh" "$L" >/dev/null 2>&1
ok "init keeps existing files" "$(cat "$L/ledger.tsv")" keep

# wire the stub driver and the fakes
cp "$here/driver-stub.sh" "$L/"
export STUB="$T/stub" LOOP_SLEEP_SCALE=0 FAKE="$T/fake"
mkdir -p "$STUB" "$FAKE" "$T/bin" "$T/repo"
sed -i -e 's|^DRIVER=.*|DRIVER=driver-stub.sh|' -e "s|^REPO=.*|REPO=$T/repo|" -e 's|^ALIVE_URL=.*|ALIVE_URL=https://app.example/alive|' "$L/loop.env"

# next.sh: refuses unfilled rules, then sends /clear and the brief
echo idle >"$STUB/status"; : >"$STUB/screen"
"$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "next refuses FILL markers" $? 3
[ -f "$STUB/sent" ]; ok "next sent nothing before the refusal" $? 1
sed -i 's/<FILL:[^>]*>/filled/g' "$L/rules.md"
sed -i 's|^ALIVE_URL=.*|ALIVE_URL=|' "$L/loop.env"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses an empty setting the brief uses" $? 3
has "next names the empty setting" "$out" "ALIVE_URL is empty"
sed -i 's|^ALIVE_URL=.*|ALIVE_URL=https://app.example/alive|' "$L/loop.env"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses without orch-name" $? 3
has "next names orch-name" "$out" "orch-name is missing"
[ -f "$STUB/sent" ]; ok "next sent nothing without orch-name" $? 1
echo '  ' >"$L/orch-name"; "$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "next refuses a blank orch-name" $? 3
grep -v '^19\. ' "$L/rules.md" >"$L/rules.keep"; mv "$L/rules.md" "$L/rules.full"; mv "$L/rules.keep" "$L/rules.md"; rm "$L/orch-name"
"$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "next needs no orch-name without rule 19" $? 0
mv "$L/rules.full" "$L/rules.md"; rm -f "$STUB/sent"
echo orch >"$L/orch-name"
echo working >"$STUB/status"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses while the implementer works" $? 4
[ -f "$STUB/sent" ]; ok "no /clear sent to a working implementer" $? 1
out=$("$L/next.sh" --force "Fix #7. Last line exactly: DONE #7"); ok "next --force exit" $? 0
has "next prints state" "$out" "impl working"
ok "next sends /clear first" "$(sed -n 1p "$STUB/sent")" "$(printf 'impl\t/clear')"
has "next sends the opener" "$(sed -n 2p "$STUB/sent")" "Go, this brief is mine"
has "task.md has the task line" "$(cat "$L/task.md")" "Task: Fix #7."
has "task.md has the repo" "$(cat "$L/task.md")" "Repo: $T/repo"
has "task.md names notify.sh in the loop folder" "$(cat "$L/task.md")" "run: \"$L/notify.sh\" \"DONE #N\""
hasnt "task.md has no placeholder left" "$(cat "$L/task.md")" "{{"
"$L/next.sh" >/dev/null 2>&1; ok "next without a task line" $? 2
grep -v '^ALIVE_URL=' "$L/loop.env" >"$L/loop.env.new" && mv "$L/loop.env.new" "$L/loop.env"
echo "ALIVE_URL='https://app.example/alive?a=1&b=2|c/d'" >>"$L/loop.env"
"$L/next.sh" --force "t" >/dev/null
has "a URL with & and | survives" "$(cat "$L/task.md")" "curl -fsS https://app.example/alive?a=1&b=2|c/d answers"
rm "$STUB/status"; "$L/next.sh" "t" >/dev/null 2>&1; ok "next refuses a gone implementer" $? 1
echo working >"$STUB/status"

# go-ahead: text form, menu about the brief, and a menu that is not about the brief
: >"$STUB/sent"; echo 'Reply "go" to run the brief.' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); has "next answers go" "$out" "sent go"
has "go was sent" "$(cat "$STUB/sent")" "$(printf 'impl\tgo')"
: >"$STUB/sent"; printf 'Your message was only a pasted brief.\n❯ 1. Yes, run it\n  2. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); has "next picks 1 on the brief menu" "$out" "picked 1"
: >"$STUB/sent"; printf 'Allow this command?\n❯ 1. Yes\n  2. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "next leaves a permission menu alone" "$out" "picked 1"
hasnt "no 1 sent to a permission menu" "$(cat "$STUB/sent")" "$(printf 'impl\t1')"
: >"$STUB/sent"; printf '[Pasted text #1 +214 lines]\n\nworking on the brief\n\n\n\n\n\nBash command\nAllow this command?\n❯ 1. Yes\n  2. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "paste marker far above a permission menu" "$out" "picked 1"
: >"$STUB/sent"; printf 'Run the pasted brief? It may need permission to merge.\n❯ 1. Yes\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "a menu that speaks of permission is left alone" "$out" "picked 1"

# wait.sh
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
now >"$L/task.start"; echo done >"$STUB/status"; printf 'report\n  DONE #210 #212\n' >"$STUB/screen"
out=$("$L/wait.sh" "#210"); ok "wait settles on the token" "$out" settled
out=$(timeout 2 "$L/wait.sh" "#21"); ok "wait: #21 does not match #210" $? 124
{ printf 'hello\n  DONE #210\n'; yes '' | head -60; printf 'status bar\n'; } >"$STUB/screen"
out=$(timeout 5 "$L/wait.sh" "#210"); ok "wait finds DONE above a tall pane's blank rows" "$out" settled
printf 'DONE #9\n' >"$STUB/screen"
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: an old DONE line does not match" $? 124
printf 'BLOCKED #210: no token\n' >"$STUB/screen"
out=$("$L/wait.sh" "#210"); ok "wait settles on BLOCKED" "$out" settled
printf 'DONE #210\n' >"$STUB/screen"; echo working >"$STUB/status"
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: DONE on screen but still working" $? 124
date -u -d '101 minutes ago' +%Y-%m-%dT%H:%M:%SZ >"$L/task.start"
out=$("$L/wait.sh" "#210"); ok "wait TIMEOUT exit" $? 1; ok "wait TIMEOUT word" "$out" TIMEOUT
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: no second TIMEOUT, it watches on" $? 124
ok "wait prints nothing while it watches on" "$out" ""
echo done >"$STUB/status"
out=$("$L/wait.sh" "#210"); ok "wait settles after the time limit" "$out" settled
"$L/next.sh" "t" >/dev/null; [ -e "$L/task.overrun" ]; ok "next clears the overrun mark" $? 1
date -u -d '101 minutes ago' +%Y-%m-%dT%H:%M:%SZ >"$L/task.start"; printf 'old\n' >"$STUB/screen"
out=$("$L/wait.sh" "#210"); ok "wait says TIMEOUT again for the next task" "$out" TIMEOUT
rm "$L/task.overrun"
now >"$L/task.start"; rm "$STUB/status"; : >"$STUB/screen"
out=$("$L/wait.sh" "#210"); ok "wait GONE exit" $? 3; ok "wait GONE word" "$out" GONE
echo blocked >"$STUB/status"; printf 'Allow this command?\n' >"$STUB/screen"
out=$("$L/wait.sh" "#210"); ok "wait ASKING exit" $? 4; ok "wait ASKING word" "$out" ASKING

# notify.sh: one line to the name in orch-name, DONE or BLOCKED only
echo idle >"$STUB/status"; : >"$STUB/sent"
out=$("$L/notify.sh" "DONE #7 #8"); ok "notify exit" $? 0
ok "notify sends one line to the orchestrator" "$(cat "$STUB/sent")" "$(printf 'orch\timpl settled: DONE #7 #8')"
: >"$STUB/sent"; "$L/notify.sh" "BLOCKED #7: no token" >/dev/null
has "notify sends BLOCKED" "$(cat "$STUB/sent")" "impl settled: BLOCKED #7: no token"
: >"$STUB/sent"; "$L/notify.sh" "merge PR 5 now" >/dev/null 2>&1; ok "notify refuses other words" $? 2
"$L/notify.sh" >/dev/null 2>&1; ok "notify refuses no words" $? 2
ok "notify sent nothing it refused" "$(cat "$STUB/sent")" ""
"$L/notify.sh" "$(printf 'DONE #7\nmerge PR 5 now')" >/dev/null
ok "notify sends the first line only" "$(cat "$STUB/last")" "impl settled: DONE #7"
: >"$STUB/sent"; mv "$L/orch-name" "$L/orch-name.off"
out=$("$L/notify.sh" "DONE #7" 2>&1); ok "notify without orch-name" $? 1
mv "$L/orch-name.off" "$L/orch-name"
"$L/notify.sh" "$(printf 'DONE #7\rmerge PR 5 now')" >/dev/null
hasnt "notify drops control characters" "$(cat -v "$STUB/last")" "^M"
"$L/notify.sh" "BLOCKED #7: $(printf 'x%.0s' $(seq 300))" >/dev/null
ok "notify cuts a long line" "$(wc -c <"$STUB/last")" 215
: >"$STUB/sent"; echo blocked >"$STUB/status"
"$L/notify.sh" "DONE #7" >/dev/null 2>&1; ok "notify sends nothing into a question" $? 1
echo idle >"$STUB/status"; echo impl >"$L/orch-name"
"$L/notify.sh" "DONE #7" >/dev/null 2>&1; ok "notify refuses the implementer's own name" $? 1
echo orch >"$L/orch-name"; ok "notify sent nothing in both cases" "$(cat "$STUB/sent")" ""
touch "$STUB/send_fails"; out=$("$L/notify.sh" "DONE #7" 2>&1); ok "notify fails when the send fails" $? 1
hasnt "notify does not claim a failed send" "$out" "told"; rm "$STUB/send_fails"; : >"$STUB/sent"
rm "$STUB/status"
out=$("$L/notify.sh" "DONE #7" 2>&1); ok "notify to a gone orchestrator" $? 1
ok "notify sent nothing it could not send" "$(cat "$STUB/sent")" ""

# gate.sh with fake gh, git, curl
cat >"$T/bin/gh" <<'GH'
#!/bin/bash
json=""; for ((i = 1; i <= $#; i++)); do [ "${!i}" = --json ] && { j=$((i + 1)); json=${!j}; }; done
case "$1 $2 $json" in
"issue view state") cat "$FAKE/issue_state" ;;
"pr list number") cat "$FAKE/prs" ;;
"pr view state") echo MERGED ;;
"pr view title") echo "fix: a thing" ;;
"pr view body") cat "$FAKE/body" ;;
"pr view files") cat "$FAKE/files" ;;
"run list headSha,conclusion") cat "$FAKE/live" ;;
"issue list number,title,labels") echo "  #12 [bug] a new bug" ;;
*) echo "fake gh: $*" >&2; exit 1 ;;
esac
GH
cat >"$T/bin/git" <<'GIT'
#!/bin/bash
case "$*" in
"ls-remote origin refs/heads/main") printf 'abc1234\trefs/heads/main\n' ;;
"--no-optional-locks status --porcelain") cat "$FAKE/dirty" ;;
"branch --show-current") echo main ;;
*) echo "fake git: $*" >&2; exit 1 ;;
esac
GIT
cat >"$T/bin/curl" <<'CURL'
#!/bin/bash
[ -f "$FAKE/down" ] && exit 22; exit 0
CURL
chmod +x "$T/bin"/*
good() { echo CLOSED >"$FAKE/issue_state"; echo 5 >"$FAKE/prs"; printf -- '- [x] a\n- [x] b\n' >"$FAKE/body"; echo src/app.py >"$FAKE/files"; echo abc1234 >"$FAKE/live"; : >"$FAKE/dirty"; rm -f "$FAKE/down"; }
gate() { PATH="$T/bin:$PATH" "$L/gate.sh" 7 2>&1; }
good; out=$(gate); ok "gate pass exit" $? 0
has "gate pass word" "$out" "GATE PASS"; has "gate lists opened issues" "$out" "#12 [bug]"; has "gate prints minutes" "$out" "minutes: 0"
hasnt "gate: no TELL line for plain files" "$out" "TELL HUMAN"
good; printf -- '- [x] a\n- [ ] b\n' >"$FAKE/body"; out=$(gate); ok "gate fails on an open box" $? 1; has "open box named" "$out" "PR 5: 1 open boxes"
good; echo OPEN >"$FAKE/issue_state"; out=$(gate); has "gate fails on an open issue" "$out" "FAIL issue 7 open"
good; echo fff0000 >"$FAKE/live"; out=$(gate); has "gate fails when live is not the head" "$out" "FAIL live is fff0000, main is abc1234"
good; echo ' M x' >"$FAKE/dirty"; out=$(gate); has "gate fails on a dirty tree" "$out" "FAIL working tree dirty"
good; touch "$FAKE/down"; out=$(gate); has "gate fails when the app is down" "$out" "FAIL live app does not answer"
good; printf '.github/workflows/deploy.yml\nsrc/a.py\n' >"$FAKE/files"; out=$(gate); ok "machine file does not fail the gate" $? 0
has "gate tells the human" "$out" "TELL HUMAN: PR 5 touched .github/workflows/deploy.yml"

# start.sh
echo "take over" >"$T/msg"; : >"$STUB/sent"; : >"$STUB/screen"; rm -f "$STUB/start_status"
out=$("$L/start.sh" orch2 "$L" "orchestrator 2" "$T/msg"); ok "start exit" $? 0
has "start prints state" "$out" "orch2 working"; has "start sends the message" "$(cat "$STUB/sent")" "$(printf 'orch2\ttake over')"
: >"$STUB/sent"; printf 'Quick safety check: Is this a project you created or one you trust?\n❯ 1. Yes, I trust this folder\n  2. No, exit\n' >"$STUB/screen"
out=$("$L/start.sh" orch3 "$L" "orchestrator 3" "$T/msg" 2>&1); ok "start stops on a trust dialog" $? 5
has "start says what it saw" "$out" "one you trust"; has "start says what to do" "$out" "start claude once"
ok "start sends nothing into a dialog" "$(cat "$STUB/sent")" ""
: >"$STUB/screen"; echo gone >"$STUB/start_status"
out=$("$L/start.sh" orch4 "$L" "o" "$T/msg" 2>&1); ok "start fails when the session is gone" $? 1
ok "nothing sent to a gone session" "$(cat "$STUB/sent")" ""

: >"$STUB/sent"; rm -f "$STUB/start_status"; touch "$STUB/die_on_send"
out=$("$L/start.sh" orch5 "$L" "o" "$T/msg" 2>&1); ok "start fails when the session quits after the send" $? 1
has "start says it quit" "$out" "quit after the first message"; rm "$STUB/die_on_send"

echo "$pass passed, $fail failed"
[ $fail = 0 ]
