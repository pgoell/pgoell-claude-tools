# wait.sh
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
test_wait() {
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
echo idle >"$STUB/status"; printf 'API Error: Connection lost mid-response.\n' >"$STUB/screen"
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: a short rest is no stall" $? 124
touch -d '21 minutes ago' "$L/task.alive"
out=$("$L/wait.sh" "#210"); ok "wait STALLED exit" $? 5; ok "wait STALLED word" "$out" STALLED
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: STALLED starts the clock anew" $? 124
touch -d '21 minutes ago' "$L/task.alive"; echo working >"$STUB/status"
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: a working session is no stall" $? 124
echo idle >"$STUB/status"; touch -d '21 minutes ago' "$L/task.alive"
"$L/next.sh" "t" >/dev/null; [ -e "$L/task.alive" ]; ok "next clears the stall clock" $? 1
printf 'old output\n29 new messages (ctrl+End) ↓\n' >"$STUB/screen"; echo 'DONE #210' >"$L/task.notified"; touch -d '21 minutes ago' "$L/task.alive"
out=$(timeout 5 "$L/wait.sh" "#210"); ok "wait settles on task.notified with a scrolled-up screen" "$out" settled
echo working >"$STUB/status"
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: task.notified but still working" $? 124
echo idle >"$STUB/status"; echo 'DONE #209' >"$L/task.notified"
out=$(timeout 2 "$L/wait.sh" "#210"); ok "wait: a task.notified with the last task's token does not match" $? 124
echo 'DONE #210' >"$L/task.notified"
out=$(timeout 2 "$L/wait.sh" "#21"); ok "wait: #21 in task.notified does not match #210" $? 124
"$L/next.sh" "t" >/dev/null; [ -e "$L/task.notified" ]; ok "next clears task.notified" $? 1
rm -f "$L/task.notified"
}
