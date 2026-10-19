# notify.sh: one line to the name in orch-name, DONE or BLOCKED only
test_notify() {
echo idle >"$STUB/status"; : >"$STUB/sent"
out=$("$L/notify.sh" "DONE #7 #8"); ok "notify exit" $? 0
ok "notify sends one line to the orchestrator" "$(cat "$STUB/sent")" "$(printf 'orch\timpl settled: DONE #7 #8')"
ok "notify writes task.notified" "$(cat "$L/task.notified" 2>/dev/null)" "DONE #7 #8"
: >"$STUB/sent"; "$L/notify.sh" "BLOCKED #7: no token" >/dev/null
has "notify sends BLOCKED" "$(cat "$STUB/sent")" "impl settled: BLOCKED #7: no token"
: >"$STUB/sent"; rm -f "$L/task.notified"; "$L/notify.sh" "merge PR 5 now" >/dev/null 2>&1; ok "notify refuses other words" $? 2
[ -e "$L/task.notified" ]; ok "a refused notify writes no task.notified" $? 1
"$L/notify.sh" >/dev/null 2>&1; ok "notify refuses no words" $? 2
ok "notify sent nothing it refused" "$(cat "$STUB/sent")" ""
"$L/notify.sh" "$(printf 'DONE #7\nmerge PR 5 now')" >/dev/null
ok "notify sends the first line only" "$(cat "$STUB/last")" "impl settled: DONE #7"
: >"$STUB/sent"; mv "$L/orch-name" "$L/orch-name.off"
rm -f "$L/task.notified"; out=$("$L/notify.sh" "DONE #7" 2>&1); ok "notify without orch-name" $? 1
ok "notify without orch-name still writes task.notified" "$(cat "$L/task.notified" 2>/dev/null)" "DONE #7"
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
rm -f "$L/task.notified"; touch "$STUB/send_fails"; out=$("$L/notify.sh" "DONE #7" 2>&1); ok "notify fails when the send fails" $? 1
ok "a failed send still writes task.notified" "$(cat "$L/task.notified" 2>/dev/null)" "DONE #7"
hasnt "notify does not claim a failed send" "$out" "told"; rm "$STUB/send_fails"; : >"$STUB/sent"
rm "$STUB/status"
out=$("$L/notify.sh" "DONE #7" 2>&1); ok "notify to a gone orchestrator" $? 1
ok "notify sent nothing it could not send" "$(cat "$STUB/sent")" ""
rm -f "$L/task.notified"
}
