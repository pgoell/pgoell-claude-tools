#!/bin/bash
# Shared by next.sh, wait.sh, gate.sh and start.sh. Source it, do not run it.
S=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$S/loop.env"
. "$S/$DRIVER"

# Sleep N seconds. LOOP_SLEEP_SCALE=0 turns every pause off (the tests use it).
nap() { sleep $(($1 * ${LOOP_SLEEP_SCALE:-1})); }

# A session that gets a pasted brief may ask for a typed go-ahead, as text
# ('Reply "go"') or as a menu about the brief. Answer it, twice at most.
# Only the six lines above the menu count: they must speak of a brief or a
# paste, and must not speak of allowing or permission. Any other menu is some
# other question (a tool permission, say): leave it for the orchestrator.
answer_go_ahead() {
  local name=$1 screen
  for _ in 1 2; do
    screen=$(drv_read "$name" 20)
    if grep -q 'Reply "go"' <<<"$screen"; then
      drv_send "$name" "go"
      echo "sent go"
    elif menu=$(grep -B6 -E '^\s*❯ 1\.' <<<"$screen") && grep -qiE 'brief|paste' <<<"$menu" &&
      ! grep -qiE 'allow|permission|approve' <<<"$menu"; then
      drv_send "$name" "1"
      echo "picked 1"
    else
      return 0
    fi
    nap 20
  done
}
