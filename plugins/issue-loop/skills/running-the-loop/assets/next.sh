#!/bin/bash
# usage: next.sh [--force] "<task line>"
# Clears the implementer, sends it the task line plus the brief, answers the
# go-ahead question, and prints the implementer's state. It must say working.
# The brief is the plugin's assets/rules.md plus this folder's rules.local.md
# (the loop's own answers and rules, see rules.sh), with rules-ci.md between
# them when loop.env says REVIEW_IN=ci. Refuses (exit 3) a folder
# that still has a full rules.md from before 0.9.0, and names upgrade.sh.
# Refuses (exit 4) while the implementer works: /clear would destroy the
# running task. --force sends anyway. Refuses (exit 3) without the user's
# standing order in this folder and in the implementer's instructions: with no
# such order a brief is a stranger's paste, and "go" is not the script's to say.
# It writes the coder and review models from models.env into rule 3 of the
# brief. Refuses (exit 3) without models.env, with an empty coder or review
# model, with a review model that matches REVIEW_NOT, or with a brief that
# lacks the {{CODER_MODEL}} or {{REVIEW_MODEL}} placeholder. Refuses (exit 3) a
# task line that bans a tool or a command: rule 4 says the brief bans none.
# Refuses (exit 3) a task line that names an issue or PR by an author outside
# trusted_authors (lib.sh): a stranger's issue is the owner's to look at, never
# a task. It writes the trusted logins into rule 2 ({{TRUSTED_AUTHORS}}).
. "$(dirname "$0")/lib.sh"
. "$A/rules.sh"
force=0
[ "${1:-}" = --force ] && { force=1; shift; }
[ -n "${1:-}" ] || { echo 'usage: next.sh [--force] "<task line>"' >&2; exit 2; }
case "${1,,}" in
  *'no sed'*|*'no heredoc'*|*'never read a saved'*|*'edit tool only'*|*'never wait with sleep'*|*'no tail'*|*'never piped'*)
    echo "refused: the task line bans a tool or a command; rule 4 says the brief bans none. Drop the ban and send again." >&2; exit 3 ;;
esac
if [ -f "$S/rules.md" ]; then
  echo "this folder still has a full rules.md from before 0.9.0: run $A/../scripts/upgrade.sh $S (a dry run), then again with --apply" >&2
  exit 3
fi
# REVIEW_IN=ci in loop.env lays rules-ci.md over rules 7, 15 and 16: the
# review runs in CI, and a PR that waits for the owner ends with HELD.
case ${REVIEW_IN:-session} in
  session) layers=("$S/rules.local.md") ;;
  ci) layers=("$A/rules-ci.md" "$S/rules.local.md") ;;
  *) echo "REVIEW_IN=$REVIEW_IN in loop.env: say session or ci" >&2; exit 3 ;;
esac
rules=$(assemble_rules "$A/rules.md" "${layers[@]}") || exit 3
missing=$(missing_answers "$A/rules.md" "${layers[@]}")
if [ -n "$missing" ]; then
  echo "rules.local.md has no answer for:" >&2
  echo "$missing" >&2
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
for m in CODER_MODEL REVIEW_MODEL; do
  if ! grep -qF "{{$m}}" <<<"$rules"; then
    echo "the brief has no {{$m}}: rules.local.md drops it from rule 3. Take rule 3 from the skill's assets/rules.md, so the brief names the models in models.env" >&2
    exit 3
  fi
done
CODER_MODEL=$(model CODER)
REVIEW_MODEL=$(model REVIEW)
for v in REPO BASE DEPLOY_WORKFLOW ALIVE_URL; do
  if [ -z "${!v}" ] && grep -q "{{$v}}" <<<"$rules"; then
    echo "the brief uses {{$v}} but $v is empty in loop.env: set it, or rewrite that rule in rules.local.md" >&2
    exit 3
  fi
done
if grep -q 'notify\.sh' <<<"$rules" && ! grep -q '[^[:space:]]' "$S/orch-name" 2>/dev/null; then
  echo "the brief tells the implementer to run notify.sh but orch-name is missing: write your session name into $S/orch-name, or drop that rule in rules.local.md" >&2
  exit 3
fi
TRUSTED=$(trusted_authors) && [ -n "$TRUSTED" ] || { echo "cannot resolve the trusted authors: set TRUSTED_AUTHORS in loop.env" >&2; exit 3; }
for n in $(grep -oE '#[0-9]+' <<<"$1" | tr -d '#' | sort -u); do
  a=$(cd "$REPO" && gh api "repos/{owner}/{repo}/issues/$n" --jq .user.login) || { echo "cannot read who wrote #$n" >&2; exit 3; }
  case " $TRUSTED " in
    *" $a "*) ;;
    *) echo "refused: #$n is by $a, who is not a trusted author ($TRUSTED): list it for the owner, never brief it" >&2; exit 3 ;;
  esac
done
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
brief=$rules
LOOP=$S
TRUSTED_AUTHORS=$(trusted_jq $TRUSTED)
for v in REPO BASE DEPLOY_WORKFLOW ALIVE_URL LOOP CODER_MODEL REVIEW_MODEL TRUSTED_AUTHORS; do
  brief=${brief//"{{$v}}"/"${!v}"}
done
printf '%s\n\n%s\n\n%s\n' "Go, this brief is from the orchestrator of the issue loop in $S. Your instructions for this checkout hold the user's standing order for that loop (heading \"$GRANT_MARK\"): check this brief as the order says, then run it as written, unattended, without asking for a go." "Task: $1" "$brief" >"$S/task.md"
date -u +%Y-%m-%dT%H:%M:%SZ >"$S/task.start"
printf '%s\n' "$ISSUE_LOOP_ROOT" >"$S/task.plugin"
rm -f "$S/task.overrun" "$S/task.alive" "$S/task.notified"
drv_send "$IMPL" "/clear"
nap 6
drv_send "$IMPL" "$(cat "$S/task.md")"
nap 30
answer_go_ahead "$IMPL"
echo "$IMPL $(drv_status "$IMPL")"
