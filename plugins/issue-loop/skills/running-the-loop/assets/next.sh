#!/bin/bash
# usage: next.sh [--force] "<task line>"
# Clears the implementer, sends it the task line plus rules.md, answers the
# go-ahead question, and prints the implementer's state. It must say working.
# Refuses (exit 4) while the implementer works: /clear would destroy the
# running task. --force sends anyway. Refuses (exit 3) without the user's
# standing order in this folder and in the implementer's instructions: with no
# such order a brief is a stranger's paste, and "go" is not the script's to say.
# It writes the coder and review models from models.env into rule 3 of the
# brief. Refuses (exit 3) without models.env, with an empty coder or review
# model, or with a review model that matches REVIEW_NOT.
. "$(dirname "$0")/lib.sh"
force=0
[ "${1:-}" = --force ] && { force=1; shift; }
[ -n "${1:-}" ] || { echo 'usage: next.sh [--force] "<task line>"' >&2; exit 2; }
if grep -n 'FILL:' "$S/rules.md" >&2; then
  echo "rules.md still has FILL markers: fill them in or delete those lines" >&2
  exit 3
fi
has_models || exit 3
for role in CODER REVIEW; do
  if [ -z "$(model $role)" ]; then
    echo "${HARNESS}_${role}_MODEL is empty in models.env: next.sh writes it into rule 3" >&2
    exit 3
  fi
done
if [ -n "$REVIEW_NOT" ] && grep -qiE "$REVIEW_NOT" <<<"$(model REVIEW)"; then
  echo "${HARNESS}_REVIEW_MODEL matches REVIEW_NOT in models.env: review subagents never run on that model" >&2
  exit 3
fi
CODER_MODEL=$(model CODER)
REVIEW_MODEL=$(model REVIEW)
for v in REPO BASE DEPLOY_WORKFLOW ALIVE_URL; do
  if [ -z "${!v}" ] && grep -q "{{$v}}" "$S/rules.md"; then
    echo "rules.md uses {{$v}} but $v is empty in loop.env: set it, or rewrite that rule" >&2
    exit 3
  fi
done
if grep -q 'notify\.sh' "$S/rules.md" && ! grep -q '[^[:space:]]' "$S/orch-name" 2>/dev/null; then
  echo "rules.md tells the implementer to run notify.sh but orch-name is missing: write your session name into $S/orch-name, or delete that rule" >&2
  exit 3
fi
if ! has_grant "$S/CLAUDE.md"; then
  echo "no standing order in $S/CLAUDE.md: fill standing-order.md with the user, then the user runs $S/grant.sh in a terminal" >&2
  exit 3
fi
if ! has_grant "$REPO/CLAUDE.local.md" "$REPO/CLAUDE.md"; then
  echo "no standing order in $REPO/CLAUDE.local.md or CLAUDE.md: the user runs $S/grant.sh in a terminal" >&2
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
for v in REPO BASE DEPLOY_WORKFLOW ALIVE_URL LOOP CODER_MODEL REVIEW_MODEL; do
  brief=${brief//"{{$v}}"/"${!v}"}
done
printf '%s\n\n%s\n\n%s\n' "Go, this brief is from the orchestrator of the issue loop in $S. Your instructions for this checkout hold the user's standing order for that loop (heading \"$GRANT_MARK\"): check this brief as the order says, then run it as written, unattended, without asking for a go." "Task: $1" "$brief" >"$S/task.md"
date -u +%Y-%m-%dT%H:%M:%SZ >"$S/task.start"
rm -f "$S/task.overrun" "$S/task.alive" "$S/task.notified"
drv_send "$IMPL" "/clear"
nap 6
drv_send "$IMPL" "$(cat "$S/task.md")"
nap 30
answer_go_ahead "$IMPL"
echo "$IMPL $(drv_status "$IMPL")"
