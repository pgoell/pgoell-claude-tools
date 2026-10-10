#!/bin/bash
# usage: notify.sh "DONE #210"   or   notify.sh "BLOCKED #210: reason"
# The implementer runs this once, as its last tool call before the final
# report. It types one line, "impl settled: <your words>", into the
# orchestrator's session, whose name is in the file orch-name in this folder.
# Only the first line counts, and it must begin with DONE or BLOCKED: this
# script is no way to send the orchestrator anything else.
# Exit 2: bad words. Exit 1: no orch-name, or no session has that name.
. "$(dirname "$0")/lib.sh"
line=$(head -1 <<<"${1:-}")
grep -qE '^(DONE|BLOCKED) ' <<<"$line" || { echo 'usage: notify.sh "DONE #N" or "BLOCKED #N: reason"' >&2; exit 2; }
orch=$(head -1 "$S/orch-name" 2>/dev/null)
[ -n "$orch" ] || { echo "no orchestrator name in $S/orch-name: nothing sent" >&2; exit 1; }
[ "$(drv_status "$orch")" = gone ] && { echo "$orch gone: nothing sent" >&2; exit 1; }
drv_send "$orch" "impl settled: $line"
echo "told $orch"
