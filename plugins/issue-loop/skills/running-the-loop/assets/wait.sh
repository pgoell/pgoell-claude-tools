#!/bin/bash
# usage: wait.sh "<token>", for example wait.sh "#210"
# The token is the first word after DONE in the last line the task line asked for.
# Run it in the background. It prints one word and exits:
#   settled  (0) the report, or the file task.notified that notify.sh writes,
#                has "DONE <token>", "BLOCKED <token>" or "HELD <token>"
#                (a PR that waits for the owner) and the session
#                rests. The file covers a scrolled-up pane that hides the
#                report; next.sh removes it with the next task.
#   TIMEOUT  (1) the task is older than TASK_LIMIT_MIN minutes. Said once per
#                task: it leaves the file task.overrun, and while that file is
#                there a new wait.sh watches on at the same pace with no limit.
#                next.sh removes the file with the next task.
#   GONE     (3) no session has the implementer's name: it died
#   ASKING   (4) the session waits on a question and has no DONE line
#   STALLED  (5) the session has not worked for STALL_MIN minutes (default 20)
#                and has no DONE line: its turn may have died on an API error.
#                The clock is the file task.alive; next.sh removes it with the
#                next task.
# Needs GNU date (date -d) and GNU stat (stat -c).
. "$(dirname "$0")/lib.sh"
tok=${1:?usage: wait.sh "<token>"}
limit=$((${TASK_LIMIT_MIN:-100} * 60))
alive="$S/task.alive"
[ -e "$alive" ] || : >"$alive"
has_token() { { screen_tail "$IMPL" 40; head -1 "$S/task.notified" 2>/dev/null; } | grep -E '^\s*(DONE|BLOCKED|HELD) ' | grep -qE " ${tok}([^0-9A-Za-z]|\$)"; }
while true; do
  age=$(($(date +%s) - $(date -d "$(cat "$S/task.start")" +%s)))
  [ "$age" -gt "$limit" ] && [ ! -e "$S/task.overrun" ] && { : >"$S/task.overrun"; echo TIMEOUT; exit 1; }
  drv_wait "$IMPL" 300
  st=$(drv_status "$IMPL")
  [ "$st" = gone ] && { echo GONE; exit 3; }
  [ "$st" = working ] && : >"$alive"
  if ! has_token && [ $(($(date +%s) - $(stat -c %Y "$alive"))) -gt $((${STALL_MIN:-20} * 60)) ]; then
    : >"$alive"
    echo STALLED
    exit 5
  fi
  if has_token; then
    nap 5
    [ "$(drv_status "$IMPL")" != working ] && break
  elif [ "$st" = blocked ]; then
    nap 5
    [ "$(drv_status "$IMPL")" = blocked ] && ! has_token && { echo ASKING; exit 4; }
  fi
  nap 60
done
echo settled
