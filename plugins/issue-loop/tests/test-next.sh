# next.sh: refuses unfilled rules, then sends /clear and the brief
test_next_refusals() {
echo idle >"$STUB/status"; : >"$STUB/screen"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses FILL markers" $? 3
has "next names the unanswered FILL" "$out" "## 1.1"
[ -f "$STUB/sent" ]; ok "next sent nothing before the refusal" $? 1
printf '## 1.1\nfilled\n## 5.1\nfilled\n## 5.2\nfilled\n## 5.3\nfilled\n## 9.1\nfilled\n## 13.1\nfilled\n## 14.1\nfilled\n' >"$L/rules.local.md"
sed -i 's|^ALIVE_URL=.*|ALIVE_URL=|' "$L/loop.env"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses an empty setting the brief uses" $? 3
has "next names the empty setting" "$out" "ALIVE_URL is empty"
sed -i 's|^ALIVE_URL=.*|ALIVE_URL=https://app.example/alive|' "$L/loop.env"
out=$("$L/next.sh" "Fix #7" 2>&1); ok "next refuses without orch-name" $? 3
has "next names orch-name" "$out" "orch-name is missing"
[ -f "$STUB/sent" ]; ok "next sent nothing without orch-name" $? 1
echo '  ' >"$L/orch-name"; "$L/next.sh" "Fix #7" >/dev/null 2>&1; ok "next refuses a blank orch-name" $? 3
}

# next.sh with the standing order in place: the brief it sends
test_next_sends() {
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
coder=$(sed -n 's/^CLAUDE_CODER_MODEL=//p' "$L/models.env")
review=$(sed -n 's/^CLAUDE_REVIEW_MODEL=//p' "$L/models.env")
has "the brief names the coder model" "$(cat "$L/task.md")" "Subagents implement on $coder"
has "the brief names the review model" "$(cat "$L/task.md")" "run on $review"
"$L/next.sh" >/dev/null 2>&1; ok "next without a task line" $? 2
grep -v '^ALIVE_URL=' "$L/loop.env" >"$L/loop.env.new" && mv "$L/loop.env.new" "$L/loop.env"
echo "ALIVE_URL='https://app.example/alive?a=1&b=2|c/d'" >>"$L/loop.env"
"$L/next.sh" --force "t" >/dev/null
out=$("$L/next.sh" --force "t. Never read a saved CI log, no sed" 2>&1); ok "next sends a task line that bans a tool" $? 0
has "next warns on a tool ban" "$out" "WARN: the task line bans a tool"
has "a URL with & and | survives" "$(cat "$L/task.md")" "curl -fsS https://app.example/alive?a=1&b=2|c/d answers"
rm "$STUB/status"; "$L/next.sh" "t" >/dev/null 2>&1; ok "next refuses a gone implementer" $? 1
}

# go-ahead: text forms, menu about the brief, and a menu that is not about the
# brief. Only a session that rests is answered.
test_next_go_ahead() {
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
}
