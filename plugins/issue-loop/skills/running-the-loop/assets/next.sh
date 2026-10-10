#!/bin/bash
# usage: next.sh "<task line>"
# Clears the implementer, sends it the task line plus rules.md, answers the
# go-ahead question, and prints the implementer's state. It must say working.
. "$(dirname "$0")/lib.sh"
[ -n "${1:-}" ] || { echo 'usage: next.sh "<task line>"' >&2; exit 2; }
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
{
  echo "Go, this brief is mine, run it as written, unattended."
  echo
  echo "Task: $1"
  echo
  sed -e "s|{{REPO}}|$REPO|g" -e "s|{{BASE}}|$BASE|g" -e "s|{{DEPLOY_WORKFLOW}}|$DEPLOY_WORKFLOW|g" -e "s|{{ALIVE_URL}}|$ALIVE_URL|g" "$S/rules.md"
} >"$S/task.md"
date -u +%Y-%m-%dT%H:%M:%SZ >"$S/task.start"
drv_send "$IMPL" "/clear"
nap 6
drv_send "$IMPL" "$(cat "$S/task.md")"
nap 30
answer_go_ahead "$IMPL"
echo "$IMPL $(drv_status "$IMPL")"
