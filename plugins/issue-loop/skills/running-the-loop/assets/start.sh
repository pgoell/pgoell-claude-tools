#!/bin/bash
# usage: start.sh <session name> <working folder> <tab label> <file with the first message>
# Starts a Claude Code session in the permission mode from loop.env, checks it
# is there, sends the first message, answers the go-ahead question, and prints
# the session's state. Used for a successor orchestrator and for side sessions.
. "$(dirname "$0")/lib.sh"
[ $# = 4 ] || { echo "usage: start.sh <name> <cwd> <label> <message file>" >&2; exit 2; }
drv_start "$1" "$2" "$3" || { echo "start failed" >&2; exit 1; }
nap 12
[ "$(drv_status "$1")" = gone ] && { echo "$1 gone: the session did not start, read its pane" >&2; exit 1; }
drv_send "$1" "$(cat "$4")"
nap 30
answer_go_ahead "$1"
echo "$1 $(drv_status "$1")"
