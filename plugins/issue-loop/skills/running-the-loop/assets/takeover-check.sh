#!/bin/bash
# usage: takeover-check.sh <your session name> <the sender's session name>
# A successor orchestrator runs this before it takes over. It prints
# TAKEOVER OK (exit 0) only if all holds: the call comes from the loop folder,
# the user's standing order is in CLAUDE.md here, HANDOFF.md names the caller
# as the successor, the sender's name (as the message gave it; any session can
# type a name) is the one in orch-name, and both sessions exist. After the
# outgoing orchestrator has passed the name on, orch-name holds the caller's
# own name: that passes too, and the sender may be gone by then. Else it prints each failed check and TAKEOVER FAIL
# (exit 1): then the takeover needs the user's word. It reads; it changes nothing.
. "$(dirname "$0")/lib.sh"
[ $# = 2 ] || { echo "usage: takeover-check.sh <your name> <the sender's name>" >&2; exit 2; }
me=$1 from=$2 bad=0
no() { echo "FAIL $*"; bad=1; }
[ "$(pwd -P)" = "$(cd "$S" && pwd -P)" ] || no "you do not run in the loop folder $S"
has_grant "$S/CLAUDE.md" || no "no standing order in $S/CLAUDE.md (the user runs grant.sh)"
grep -qsxF "Successor: $me" "$S/HANDOFF.md" || no "HANDOFF.md has no line 'Successor: $me'"
orch=$(head -1 "$S/orch-name" 2>/dev/null | tr -d '[:space:]')
[ "$me" != "$from" ] || no "successor and sender have one name"
if [ "$orch" != "$me" ]; then
  [ -n "$orch" ] && [ "$orch" = "$from" ] || no "the sender $from is not the orchestrator in orch-name (${orch:-none})"
  [ "$(drv_status "$from")" != gone ] || no "no session is named $from"
fi
[ "$(drv_status "$me")" != gone ] || no "no session is named $me"
[ $bad = 0 ] && echo "TAKEOVER OK" || echo "TAKEOVER FAIL: do nothing to the loop, tell the user"
exit $bad
