#!/bin/bash
# Shared by the scripts of the plugin. Source it, do not run it. The stub in the
# loop folder sets ISSUE_LOOP_DIR to that folder; the script's own folder is A.
# The loop folder is the state, and the physical path keeps the name the same
# whatever link the folder was reached by.
S=${ISSUE_LOOP_DIR:-}
[ -n "$S" ] || { echo "run this script through the stub in a loop folder: ISSUE_LOOP_DIR is not set" >&2; exit 2; }
A=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$S/loop.env"
# A folder made before 0.8.0 has no models.env; next.sh and start.sh refuse without it, the other scripts run.
[ -f "$S/models.env" ] && . "$S/models.env"
# A driver in the loop folder is the loop's own; else the plugin's.
if [ -f "$S/$DRIVER" ]; then . "$S/$DRIVER"; else . "$A/$DRIVER"; fi

# The model for ROLE (ORCH, IMPL, CODER, REVIEW or ADVISOR) in the harness of models.env. Empty when unset.
model() { local v="${HARNESS}_$1_MODEL"; echo "${!v:-}"; }

# has_models: true when models.env is in the loop folder. Else says the fix on stderr.
has_models() {
  [ -f "$S/models.env" ] || { echo "no models.env in $S: run $A/../scripts/upgrade.sh $S" >&2; return 1; }
}

# installed_root: the folder of the installed issue-loop, from installed_plugins.json. Empty when none.
installed_root() {
  local reg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json" p
  jq -r '.plugins | to_entries[] | select(.key | startswith("issue-loop@")) | .value[].installPath' "$reg" 2>/dev/null | while read -r p; do printf '%s\t%s\n' "$(basename "$p")" "$p"; done | sort -V | tail -1 | cut -f2 || true
}

# Sleep N seconds. LOOP_SLEEP_SCALE=0 turns every pause off (the tests use it).
nap() { sleep $(($1 * ${LOOP_SLEEP_SCALE:-1})); }

# Print the last N lines of a session's screen that are not blank. A tall pane
# pads a short report with blank rows, so a plain read of N lines can miss it.
screen_tail() { drv_read "$1" 200 2>/dev/null | grep -vE '^\s*$' | tail -n "$2"; }

# The user's standing order for this loop: the heading that grant.sh writes
# into CLAUDE.md in this folder and into the implementer's instructions.
# has_grant FILE...: true when one of the files holds it.
GRANT_MARK="issue-loop standing order: $S"
has_grant() { grep -qsxF "## $GRANT_MARK" "$@"; }

# A session that gets a pasted brief may still ask for a typed go-ahead, as
# text ('Reply "go"', 'Confirm with one word ("go")') or as a menu about the
# brief. Answer it, twice at most, and never the same screen twice. The caller
# must have checked that the standing order covers what was sent: "go" is the
# user's word, and the scripts may say it only for a brief from next.sh and
# for a takeover. The second argument, when given, is the text sent in place
# of a bare "go": start.sh marks its go as one for the takeover only, so the
# successor does not read it as the user's go on whatever its report asks.
# A working session asks nothing, so only a session that rests is read. A
# screen that speaks of a failed takeover check or of a stopped loop is never
# answered.
# Text form: a line that asks for the word go (GO_ASK) and names nothing that
# a go must not wave through (GO_NOT). Menu form: the lines above the menu
# must speak of a brief or a paste, and the menu with its six lines above and
# three below must not look like a tool permission (MENU_NOT). Claude Code
# words that one "Do you want to proceed?". Any other menu is some other
# question: leave it for the orchestrator.
GO_VERB='(^|[^[:alpha:]])(reply|respond|answer|confirm|type|say|send)'
GO_ASK="$GO_VERB[^[:alpha:]][^.]{0,60}[\"'\`*(]go[\"'\`*)]|$GO_VERB go([^[:alnum:]-]|\$)|(waiting for|awaiting|need) (your |a )?[\"'\`*]?go([^[:alnum:]]|\$)"
GO_NOT='refuse|refusal|refusing|hook|force|delete|deleting|remove|removing|without|instead|anyway|skip|fail|stop'
MENU_NOT="allow|permission|approve|proceed|do you want|don.t ask|bash command|edit file|write file"
answer_go_ahead() {
  local name=$1 go=${2:-go} screen menu last=
  for _ in 1 2; do
    [ "$(drv_status "$name")" = working ] && return 0
    screen=$(screen_tail "$name" 20)
    [ "$screen" != "$last" ] || return 0
    last=$screen
    grep -qE 'TAKEOVER FAIL|STOPPED' <<<"$screen" && return 0
    if grep -qE '^\s*❯ 1\.' <<<"$screen"; then
      menu=$(grep -B6 -A3 -E '^\s*❯ 1\.' <<<"$screen")
      grep -B6 -E '^\s*❯ 1\.' <<<"$screen" | grep -qiE 'brief|paste' && ! grep -qiE "$MENU_NOT" <<<"$menu" || return 0
      drv_send "$name" "1"
      echo "picked 1"
    elif grep -iE "$GO_ASK" <<<"$screen" | grep -qviE "$GO_NOT"; then
      drv_send "$name" "$go"
      echo "sent go"
    else
      return 0
    fi
    nap 20
  done
}

# Anyone can open or comment on an issue of a public repo, so a stranger's text
# would reach a session as part of its task. The loop reads issue and PR text
# only from trusted authors. trusted_authors: their logins, space between:
# TRUSTED_AUTHORS from loop.env, else the repo's owner, the account of the
# GH_TOKEN in IMPL_ENV_FILE (read in a subshell, never printed), and with
# REVIEW_IN=ci github-actions[bot], which posts the CI review.
trusted_authors() {
  [ -n "${TRUSTED_AUTHORS:-}" ] && { echo "$TRUSTED_AUTHORS"; return 0; }
  local who
  who=$(cd "$REPO" && gh api 'repos/{owner}/{repo}' --jq .owner.login) && [ -n "$who" ] || return 1
  if [ -n "${IMPL_ENV_FILE:-}" ]; then
    who+=" $(set -a; . "$IMPL_ENV_FILE"; set +a; gh api user --jq .login)" || return 1
  fi
  [ "${REVIEW_IN:-session}" = ci ] && who+=" github-actions[bot]"
  echo "$who"
}

# trusted_jq LOGIN...: the logins as the argument list of jq's IN(), "a","b".
trusted_jq() { local a out=""; for a in "$@"; do out+="${out:+,}\"$a\""; done; echo "$out"; }

# trusted_queue: the open issues by trusted authors, then the ones by anyone
# else under a heading: those are the owner's to look at, never a task.
trusted_queue() {
  local who in
  who=$(trusted_authors) || { echo "cannot resolve the trusted authors: set TRUSTED_AUTHORS in loop.env" >&2; return 1; }
  in=$(trusted_jq $who)
  (cd "$REPO" && gh api --paginate 'repos/{owner}/{repo}/issues?state=open&per_page=100' --jq "
    (.[] | select(.pull_request | not) | select(.user.login | IN($in)) | \"#\(.number) [\([.labels[].name] | join(\",\"))] \(.title)\"),
    (.[] | select(.pull_request | not) | select(.user.login | IN($in) | not) | \"NOT TRUSTED, for the owner: #\(.number) by \(.user.login): \(.title)\")")
}

# trusted_read N: issue or PR N with its comments, the text of trusted authors
# only. For the rest it names the author and leaves the text unread.
trusted_read() {
  local who in
  who=$(trusted_authors) || { echo "cannot resolve the trusted authors: set TRUSTED_AUTHORS in loop.env" >&2; return 1; }
  in=$(trusted_jq $who)
  (cd "$REPO" && gh api "repos/{owner}/{repo}/issues/$1" --jq "if .user.login | IN($in) then \"#\(.number) \(.title), by \(.user.login)\n\(.body // \"\")\" else \"#\(.number) is by \(.user.login), not trusted: unread\" end" &&
    gh api --paginate "repos/{owner}/{repo}/issues/$1/comments" --jq ".[] | if .user.login | IN($in) then \"--- \(.user.login):\n\(.body)\" else \"--- a comment by \(.user.login), not trusted: unread\" end")
}
