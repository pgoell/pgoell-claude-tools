#!/bin/bash
# usage: tests/run.sh
# Runs the loop's script templates against a stub driver and fake gh, git and
# curl. No session, no network. Needs bash, jq, GNU date, timeout, and script
# from util-linux (grant.sh wants a terminal).
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
for f in loop.env lib.sh next.sh wait.sh gate.sh start.sh notify.sh grant.sh takeover-check.sh standing-order.md standing-order-impl.md rules.md ledger.tsv driver-herdr.sh HANDOFF.md; do
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

# grant.sh: the user's standing order, only from a terminal and a typed yes
echo orch >"$L/orch-name"; git -C "$T/repo" init -q
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses without a standing order" $? 3
has "next names the missing order" "$out" "no standing order in $L/CLAUDE.md"
[ -f "$STUB/sent" ]; ok "next sent nothing without a standing order" $? 1
tty_run() { printf '%s\n' "$1" | script -qec "$L/grant.sh" /dev/null 2>&1; }
out=$("$L/grant.sh" </dev/null 2>&1); ok "grant refuses without a terminal" $? 2
out=$(tty_run yes); ok "grant refuses FILL markers" $? 3
sed -i 's/<FILL:[^>]*>/filled/g' "$L/standing-order.md"
out=$(tty_run no); ok "grant without a yes" $? 1
has "grant shows the order before it asks" "$out" "## issue-loop standing order: $L"
[ -e "$L/CLAUDE.md" ] || [ -e "$T/repo/CLAUDE.local.md" ]; ok "nothing written without a yes" $? 1
out=$(tty_run yes); ok "grant exit" $? 0
has "the loop folder holds the order" "$(cat "$L/CLAUDE.md")" "## issue-loop standing order: $L"
has "the order names the implementer" "$(cat "$L/CLAUDE.md")" 'the implementer `impl`'
hasnt "the order has no placeholder left" "$(cat "$L/CLAUDE.md" "$T/repo/CLAUDE.local.md")" "{{"
has "the checkout holds the order" "$(cat "$T/repo/CLAUDE.local.md")" "## issue-loop standing order: $L"
has "the order is kept out of git" "$(cat "$T/repo/.git/info/exclude")" "CLAUDE.local.md"
ok "the checkout stays clean" "$(git -C "$T/repo" status --porcelain)" ""
out=$(tty_run yes); has "a second grant changes nothing" "$out" "already in $L/CLAUDE.md"
ok "the order is there once" "$(grep -c '^## issue-loop standing order' "$L/CLAUDE.md")" 1
git init -q "$T/tracked"; echo mine >"$T/tracked/CLAUDE.local.md"; git -C "$T/tracked" add CLAUDE.local.md
mkdir "$T/ro"; chmod a-w "$T/ro"; git init -q "$T/nonl"; printf '*.log' >"$T/nonl/.git/info/exclude"
cp -r "$L" "$T/loop2"; rm "$T/loop2/CLAUDE.md"
grant2() { sed -i "s|^REPO=.*|REPO=$1|" "$T/loop2/loop.env"; printf 'yes\n' | script -qec "$T/loop2/grant.sh" /dev/null 2>&1; }
out=$(grant2 "$T/tracked"); ok "grant refuses a tracked CLAUDE.local.md" $? 1
ok "the tracked file is left alone" "$(cat "$T/tracked/CLAUDE.local.md")" mine
out=$(grant2 "$T/ro"); ok "grant fails when it cannot write" $? 1
hasnt "a failed grant does not say granted" "$out" "granted."; [ -e "$T/loop2/CLAUDE.md" ]; ok "a failed grant writes neither file" $? 1
out=$(grant2 "$T/nonl"); ok "grant with an exclude file that has no last newline" $? 0
ok "that checkout stays clean" "$(git -C "$T/nonl" status --porcelain)" ""
chmod u+w "$T/ro"; ln -s "$L" "$T/link"
mv "$T/repo/CLAUDE.local.md" "$T/impl-order"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses without the implementer's order" $? 3
has "next names the checkout" "$out" "no standing order in $T/repo/CLAUDE.local.md"
cp "$T/impl-order" "$T/repo/CLAUDE.md"; "$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "the order may sit in the checkout's CLAUDE.md" $? 0
rm "$T/repo/CLAUDE.md" "$STUB/sent"; mv "$T/impl-order" "$T/repo/CLAUDE.local.md"
"$T/link/next.sh" "Fix #7" >/dev/null 2>&1; ok "the order holds when the folder is reached through a link" $? 0; rm "$STUB/sent"
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
has "next sends the opener" "$(sed -n 2p "$STUB/sent")" "Go, this brief is from the orchestrator of the issue loop in $L."
has "the opener points at the standing order" "$(sed -n 2p "$STUB/sent")" "issue-loop standing order: $L"
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

# go-ahead: text forms, menu about the brief, and a menu that is not about the
# brief. Only a session that rests is answered.
echo done >"$STUB/status"
: >"$STUB/sent"; echo 'Reply "go" to run the brief.' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); has "next answers go" "$out" "sent go"
has "go was sent" "$(cat "$STUB/sent")" "$(printf 'impl\tgo')"
for ask in 'Confirm with one word ("go") and I start.' 'Say go and I will run it.' 'I am waiting for your go.' 'Reply with `go` to start.'; do
  : >"$STUB/sent"; echo "$ask" >"$STUB/screen"
  out=$("$L/next.sh" --force "t"); has "next answers: $ask" "$out" "sent go"
done
for plain in 'I will go on with the deploy now.' 'Confirmed. The goal is one PR.' "$(head -1 "$L/task.md")" \
  'I will send the PR link once the checks go green' 'I confirmed that tests go through' 'The prototype lets users go back' \
  'The hook refused git push --force. Confirm with "go" and I will use the API instead' 'Say go and I will merge without the review.' \
  'TAKEOVER FAIL: HANDOFF.md has no line for me. Reply "go" if you want me to take over.' \
  'HANDOFF.md begins with STOPPED. Reply "go" to start the loop again.'; do
  : >"$STUB/sent"; echo "$plain" >"$STUB/screen"
  out=$("$L/next.sh" --force "t"); hasnt "next sends no go for: $plain" "$out" "sent go"
done
: >"$STUB/sent"; echo 'Reply "go" to run the brief.' >"$STUB/screen"; "$L/next.sh" --force "t" >/dev/null
ok "one go for a screen that does not change" "$(grep -c "$(printf 'impl\tgo')" "$STUB/sent")" 1
echo working >"$STUB/status"; : >"$STUB/sent"; echo 'Reply "go" to run the brief.' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "a working session is not answered" "$out" "sent go"
echo blocked >"$STUB/status"
: >"$STUB/sent"; printf 'Your message was only a pasted brief.\n❯ 1. Yes, run it\n  2. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); has "next picks 1 on the brief menu" "$out" "picked 1"
: >"$STUB/sent"; printf 'Allow this command?\n❯ 1. Yes\n  2. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "next leaves a permission menu alone" "$out" "picked 1"
hasnt "no 1 sent to a permission menu" "$(cat "$STUB/sent")" "$(printf 'impl\t1')"
: >"$STUB/sent"; printf '[Pasted text #1 +214 lines]\n\nworking on the brief\n\n\n\n\n\nBash command\nAllow this command?\n❯ 1. Yes\n  2. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "paste marker far above a permission menu" "$out" "picked 1"
: >"$STUB/sent"; printf 'Run the pasted brief? It may need permission to merge.\n❯ 1. Yes\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "a menu that speaks of permission is left alone" "$out" "picked 1"
: >"$STUB/sent"; printf 'Bash command\n  gh pr merge 12 --admin --squash   # as the brief says\n  Merge PR 12 past the failing check\nDo you want to proceed?\n❯ 1. Yes\n  2. Yes, and do not ask again for gh pr merge\n  3. No\n' >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "Claude Code's permission dialog is left alone" "$out" "picked 1"
: >"$STUB/sent"; printf "Your message was a pasted brief.\nRun it?\n❯ 1. Yes\n  2. Yes, and don't ask again\n" >"$STUB/screen"
out=$("$L/next.sh" --force "t"); hasnt "a menu that offers not to ask again is left alone" "$out" "picked 1"

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

# takeover-check.sh: the successor's checks before it takes over
echo idle >"$STUB/status"; printf '# Handoff\n\nSuccessor: orch2\n' >"$L/HANDOFF.md"
check() { (cd "${3:-$L}" && "$L/takeover-check.sh" "$1" "$2" 2>&1); }
out=$(check orch2 orch); ok "takeover check passes" $? 0; ok "takeover check word" "$out" "TAKEOVER OK"
out=$(check orch2 orch "$T"); ok "takeover check fails outside the loop folder" $? 1
has "it names the folder" "$out" "FAIL you do not run in the loop folder"
out=$(check orch2 stranger); has "a sender that is not in orch-name fails" "$out" "FAIL the sender stranger is not the orchestrator in orch-name (orch)"
out=$(check orch3 orch); has "a successor HANDOFF.md does not name fails" "$out" "FAIL HANDOFF.md has no line 'Successor: orch3'"
printf 'Successor: orch\n' >"$L/HANDOFF.md"
out=$(check orch orch); has "a session cannot name itself successor" "$out" "FAIL successor and sender have one name"
printf 'Successor: orch2\n' >"$L/HANDOFF.md"; touch "$STUB/gone.orch2"
out=$(check orch2 orch); has "a successor that is no session fails" "$out" "FAIL no session is named orch2"
rm "$STUB/gone.orch2"; : >"$L/orch-name"
out=$(check orch2 orch); has "an empty orch-name fails" "$out" "orch-name (none)"
echo orch2 >"$L/orch-name"; touch "$STUB/gone.orch"
out=$(check orch2 orch); ok "the check still passes after the name was passed on" "$out" "TAKEOVER OK"
rm "$STUB/gone.orch"; echo orch >"$L/orch-name"
mv "$L/CLAUDE.md" "$L/CLAUDE.off"
out=$(check orch2 orch); ok "takeover check fails without the standing order" $? 1
has "it says who grants" "$out" "the user runs grant.sh"; has "it ends with the verdict" "$out" "TAKEOVER FAIL"
mv "$L/CLAUDE.off" "$L/CLAUDE.md"; rm "$STUB/status"
out=$(check orch2 orch); has "a gone sender fails" "$out" "FAIL no session is named orch"
"$L/takeover-check.sh" orch2 >/dev/null 2>&1; ok "takeover check wants two names" $? 2

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

# start.sh answers a go-ahead question only for the successor HANDOFF.md names
: >"$STUB/sent"; echo done >"$STUB/start_status"; echo 'Confirm with one word ("go")' >"$STUB/screen"
out=$("$L/start.sh" orch2 "$L" "o" "$T/msg" 2>&1); has "start answers go for the named successor" "$out" "sent go"
for where in "$L" "$T/repo" "$T"; do
  : >"$STUB/sent"
  out=$("$L/start.sh" side1 "$where" "s" "$T/msg" 2>&1); hasnt "start sends no go to another session in $where" "$out" "sent go"
  has "start says whose answer it is" "$out" "the answer is the user's"
  hasnt "no go went to the side session" "$(cat "$STUB/sent")" "$(printf 'side1\tgo')"
done
: >"$STUB/sent"; echo 'TAKEOVER FAIL: no standing order. Reply "go" to take over anyway.' >"$STUB/screen"
out=$("$L/start.sh" orch2 "$L" "o" "$T/msg" 2>&1); hasnt "start sends no go after a failed takeover check" "$out" "sent go"
rm "$STUB/start_status"

echo "$pass passed, $fail failed"
[ $fail = 0 ]
