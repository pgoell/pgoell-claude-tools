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

# IMPL_ENV_FILE: the implementer's own credentials, for its session only
"$L/start.sh" impl "$L" "i" "$T/msg" >/dev/null 2>&1
ok "no IMPL_ENV_FILE: the driver loads no file" "$(cat "$STUB/start_env")" "|"
mkdir -p "$T/secrets"; echo 'GH_TOKEN=bot-token' >"$T/secrets/impl.env"; chmod 600 "$T/secrets/impl.env"
echo "IMPL_ENV_FILE=$T/secrets/impl.env" >>"$L/loop.env"
"$L/start.sh" impl "$L" "i" "$T/msg" >/dev/null 2>&1; ok "start with IMPL_ENV_FILE exit" $? 0
ok "the implementer gets the file, start.sh not its values" "$(cat "$STUB/start_env")" "$T/secrets/impl.env|"
"$L/start.sh" orch2 "$L" "o" "$T/msg" >/dev/null 2>&1
ok "an orchestrator never gets IMPL_ENV_FILE" "$(cat "$STUB/start_env")" "|"
chmod 644 "$T/secrets/impl.env"; rm -f "$STUB/start_env"
out=$("$L/start.sh" impl "$L" "i" "$T/msg" 2>&1); ok "start refuses an env file that others can read" $? 3
has "start says chmod 600" "$out" "chmod 600"; [ -e "$STUB/start_env" ]; ok "nothing started for a readable env file" $? 1
cp -p "$T/secrets/impl.env" "$T/repo/impl.env"; chmod 600 "$T/repo/impl.env"
sed -i "s|^IMPL_ENV_FILE=.*|IMPL_ENV_FILE=$T/repo/impl.env|" "$L/loop.env"
out=$("$L/start.sh" impl "$L" "i" "$T/msg" 2>&1); ok "start refuses an env file in the checkout" $? 3
has "start says move it out" "$out" "move it out"; rm "$T/repo/impl.env"
out=$("$L/start.sh" impl "$L" "i" "$T/msg" 2>&1); ok "start refuses a missing env file" $? 3
# the herdr driver loads the file in the tab's shell before claude starts
mkdir -p "$T/hbin"; printf '#!/bin/bash\nprintf "%%s\\n" "$*" >>"$T/herdr.log"\n[ "$1 $2" = "tab create" ] && echo "{\\"pane_id\\":\\"p9\\"}"\nexit 0\n' >"$T/hbin/herdr"; chmod +x "$T/hbin/herdr"
: >"$T/herdr.log"
( export PATH="$T/hbin:$PATH" T; nap() { :; }; . "$skill/assets/driver-herdr.sh"; SESSION_ENV_FILE="$T/secrets/impl.env" drv_start impl "$T/repo" i >/dev/null )
ok "herdr: the env file loads before claude starts" "$(grep -o '^pane run p9 .*\|^agent start impl' "$T/herdr.log" | tr '\n' '|')" "pane run p9 set -a; . $T/secrets/impl.env; set +a|agent start impl|"
: >"$T/herdr.log"
( export PATH="$T/hbin:$PATH" T; nap() { :; }; . "$skill/assets/driver-herdr.sh"; SESSION_ENV_FILE= drv_start orch2 "$L" o >/dev/null )
hasnt "herdr: no env file, no pane run" "$(cat "$T/herdr.log")" "pane run"
grep -v '^IMPL_ENV_FILE=' "$L/loop.env" >"$L/loop.env.new" && mv "$L/loop.env.new" "$L/loop.env"
rm -f "$STUB/start_status"
}
