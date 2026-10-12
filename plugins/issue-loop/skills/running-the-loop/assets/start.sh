#!/bin/bash
# usage: start.sh <session name> <working folder> <tab label> <file with the first message>
# Starts a Claude Code session in the permission mode from loop.env, checks it
# is there, sends the first message, answers the go-ahead question, and prints
# the session's state. Used for a successor orchestrator and for side sessions.
# The go-ahead question is answered only when the working folder holds the
# user's standing order; in any other folder the answer is the user's.
# Exit 5: a start dialog shows, nothing was sent. Exit 1: the session is gone.
. "$(dirname "$0")/lib.sh"
[ $# = 4 ] || { echo "usage: start.sh <name> <cwd> <label> <message file>" >&2; exit 2; }
handle=$(drv_start "$1" "$2" "$3") || { echo "start failed" >&2; exit 1; }
nap 12
# Look before the first send. A start dialog (folder trust, or any menu with
# "No, exit") takes the first message's Enter as its answer and the session
# quits. During a dialog the session may not be readable by name yet, so fall
# back to the handle that drv_start printed.
screen=$(screen_tail "$1" 30)
[ -n "$screen" ] || screen=$(screen_tail "$handle" 30)
if grep -qiE 'No, exit|one you trust|trust this folder' <<<"$screen"; then
  {
    echo "START DIALOG in $1 ($handle): nothing sent. The screen says:"
    tail -8 <<<"$screen" | sed 's/^/  | /'
    echo "Trusting a folder is the user's choice. Ask the user to start claude once in"
    echo "$2 and accept, or to name a folder they trust. Then close this pane and run start.sh again."
  } >&2
  exit 5
fi
[ "$(drv_status "$1")" = gone ] && { echo "$1 gone before the first message: read $handle" >&2; exit 1; }
drv_send "$1" "$(cat "$4")"
nap 30
if has_grant "$2/CLAUDE.md" "$2/CLAUDE.local.md"; then
  answer_go_ahead "$1"
else
  echo "no standing order in $2: if $1 asks for a go-ahead, the answer is the user's" >&2
fi
st=$(drv_status "$1")
echo "$1 $st"
[ "$st" = gone ] && { echo "$1 quit after the first message: read $handle" >&2; exit 1; }
exit 0
