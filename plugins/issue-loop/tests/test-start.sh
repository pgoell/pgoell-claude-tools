# start.sh
test_start() {
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
has "start marks its go as for the takeover only" "$(cat "$STUB/sent")" "$(printf 'orch2\tgo (typed by start.sh for the takeover only; not the user')"
for where in "$L" "$T/repo" "$T"; do
  : >"$STUB/sent"
  out=$("$L/start.sh" side1 "$where" "s" "$T/msg" 2>&1); hasnt "start sends no go to another session in $where" "$out" "sent go"
  has "start says whose answer it is" "$out" "the answer is the user's"
  hasnt "no go went to the side session" "$(cat "$STUB/sent")" "$(printf 'side1\tgo')"
done
: >"$STUB/sent"; echo 'TAKEOVER FAIL: no standing order. Reply "go" to take over anyway.' >"$STUB/screen"
out=$("$L/start.sh" orch2 "$L" "o" "$T/msg" 2>&1); hasnt "start sends no go after a failed takeover check" "$out" "sent go"
rm "$STUB/start_status"

# models: the implementer's model for the session named IMPL, the orchestrator's for the rest
models=$(cat "$L/models.env")
sed -i -e 's/^CLAUDE_ORCH_MODEL=.*/CLAUDE_ORCH_MODEL=orch-m/' -e 's/^CLAUDE_IMPL_MODEL=.*/CLAUDE_IMPL_MODEL=impl-m/' -e 's/^CLAUDE_ADVISOR_MODEL=.*/CLAUDE_ADVISOR_MODEL=adv-m/' "$L/models.env"
"$L/start.sh" orch2 "$L" "o" "$T/msg" >/dev/null 2>&1
ok "start passes the orchestrator model" "$(cat "$STUB/start_models")" "orch-m|adv-m"
"$L/start.sh" impl "$L" "i" "$T/msg" >/dev/null 2>&1
ok "start passes the implementer model" "$(cat "$STUB/start_models")" "impl-m|adv-m"
sed -i 's/^CLAUDE_ADVISOR_MODEL=.*/CLAUDE_ADVISOR_MODEL=/' "$L/models.env"
"$L/start.sh" orch2 "$L" "o" "$T/msg" >/dev/null 2>&1
ok "an empty advisor model passes no flag" "$(cat "$STUB/start_models")" "orch-m|"
printf '%s\n' "$models" >"$L/models.env"
rm -f "$STUB/start_status"
}
