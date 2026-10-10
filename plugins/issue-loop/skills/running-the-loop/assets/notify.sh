#!/bin/bash
# usage: notify.sh "DONE #210"   or   notify.sh "BLOCKED #210: reason"
# The implementer runs this once, as its last tool call before the final
# report. It types one line, "impl settled: <your words>", into the
# orchestrator's session, whose name is in the file orch-name in this folder.
# Only the first line counts, cut to 200 characters with control characters
# dropped, and it must begin with DONE or BLOCKED. It sends nothing while the
# orchestrator sits on a question: the Enter would answer that question.
# Exit 2: bad words. Exit 1: nothing sent (no orch-name, the name is the
# implementer's own, no such session, a session on a question, a failed send).
. "$(dirname "$0")/lib.sh"
line=$(tr -d '\000-\011\013-\037\177' <<<"${1:-}" | head -1 | cut -c1-200)
grep -qE '^(DONE|BLOCKED) ' <<<"$line" || { echo 'usage: notify.sh "DONE #N" or "BLOCKED #N: reason"' >&2; exit 2; }
orch=$(head -1 "$S/orch-name" 2>/dev/null | tr -d '[:space:]')
[ -n "$orch" ] || { echo "no orchestrator name in $S/orch-name: nothing sent" >&2; exit 1; }
[ "$orch" != "$IMPL" ] || { echo "orch-name holds the implementer's own name: nothing sent" >&2; exit 1; }
st=$(drv_status "$orch")
case "$st" in
working | idle | done | unknown) ;;
*) echo "$orch is '$st': nothing sent" >&2; exit 1 ;;
esac
drv_send "$orch" "impl settled: $line" || { echo "send to $orch failed" >&2; exit 1; }
echo "told $orch"
