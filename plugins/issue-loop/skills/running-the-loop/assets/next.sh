#!/bin/bash
# usage: next.sh [--force] "<task line>"
# Clears the implementer, sends it the task line plus rules.md, answers the
# go-ahead question, and prints the implementer's state. It must say working.
# Refuses (exit 4) while the implementer works: /clear would destroy the
# running task. --force sends anyway.
. "$(dirname "$0")/lib.sh"
force=0
[ "${1:-}" = --force ] && { force=1; shift; }
[ -n "${1:-}" ] || { echo 'usage: next.sh [--force] "<task line>"' >&2; exit 2; }
if grep -n 'FILL:' "$S/rules.md" >&2; then
  echo "rules.md still has FILL markers: fill them in or delete those lines" >&2
  exit 3
fi
for v in REPO BASE DEPLOY_WORKFLOW ALIVE_URL; do
  if [ -z "${!v}" ] && grep -q "{{$v}}" "$S/rules.md"; then
    echo "rules.md uses {{$v}} but $v is empty in loop.env: set it, or rewrite that rule" >&2
    exit 3
  fi
done
if grep -q 'notify\.sh' "$S/rules.md" && [ ! -s "$S/orch-name" ]; then
  echo "rules.md tells the implementer to run notify.sh but orch-name is missing: write your session name into $S/orch-name, or delete that rule" >&2
  exit 3
fi
st=$(drv_status "$IMPL")
if [ "$st" = working ] && [ $force = 0 ]; then
  echo "$IMPL is working: /clear would destroy its task. Wait for it, or pass --force" >&2
  exit 4
fi
[ "$st" = gone ] && { echo "$IMPL gone: no session has that name" >&2; exit 1; }
# Plain text replacement: a value may hold &, | or / (a URL with a query string).
brief=$(<"$S/rules.md")
LOOP=$S
for v in REPO BASE DEPLOY_WORKFLOW ALIVE_URL LOOP; do
  brief=${brief//"{{$v}}"/"${!v}"}
done
printf '%s\n\n%s\n\n%s\n' "Go, this brief is mine, run it as written, unattended." "Task: $1" "$brief" >"$S/task.md"
date -u +%Y-%m-%dT%H:%M:%SZ >"$S/task.start"
rm -f "$S/task.overrun"
drv_send "$IMPL" "/clear"
nap 6
drv_send "$IMPL" "$(cat "$S/task.md")"
nap 30
answer_go_ahead "$IMPL"
echo "$IMPL $(drv_status "$IMPL")"
