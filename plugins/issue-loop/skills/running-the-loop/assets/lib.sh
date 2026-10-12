#!/bin/bash
# Shared by the scripts in this folder. Source it, do not run it.
S=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$S/loop.env"
. "$S/$DRIVER"

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
# brief. Answer it, twice at most. The caller must have checked that the
# session's folder holds the standing order: "go" is the user's word, and the
# scripts may say it only for what that order covers.
# A working session asks nothing, so only a session that rests is read.
# Text form: a line that asks for the word go. Menu form: only the six lines
# above the menu count; they must speak of a brief or a paste, and must not
# speak of allowing or permission. Any other menu is some other question (a
# tool permission, say): leave it for the orchestrator.
GO_ASK='(reply|respond|answer|confirm|type|say|send)[^.]{0,60}[^[:alnum:]]go([^[:alnum:]]|$)|waiting for (your |a )?"?go"?([^[:alnum:]]|$)'
answer_go_ahead() {
  local name=$1 screen menu
  for _ in 1 2; do
    [ "$(drv_status "$name")" = working ] && return 0
    screen=$(screen_tail "$name" 20)
    if menu=$(grep -B6 -E '^\s*❯ 1\.' <<<"$screen"); then
      grep -qiE 'brief|paste' <<<"$menu" && ! grep -qiE 'allow|permission|approve' <<<"$menu" || return 0
      drv_send "$name" "1"
      echo "picked 1"
    elif grep -qiE "$GO_ASK" <<<"$screen"; then
      drv_send "$name" "go"
      echo "sent go"
    else
      return 0
    fi
    nap 20
  done
}
