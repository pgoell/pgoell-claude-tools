#!/bin/bash
# usage: grant.sh          (the user runs it, in a terminal of their own)
# Puts the user's standing order in place, so that the loop's sessions need no
# typed go for a brief or a takeover:
#   standing-order.md       ->  CLAUDE.md in this folder (orchestrators)
#   standing-order-impl.md  ->  CLAUDE.local.md in the implementer's checkout,
#                               kept out of git through .git/info/exclude
# It prints both texts and writes only after a typed yes. It refuses without a
# terminal: a session must not grant itself the user's order.
# Exit 2: no terminal. Exit 3: a FILL marker is left. Exit 1: not granted
# (no yes, REPO is no folder, CLAUDE.local.md is tracked, a file cannot be written).
. "$(dirname "$0")/lib.sh"
[ -t 0 ] || { echo "grant.sh needs a terminal: the user runs it, no session does" >&2; exit 2; }
if grep -n 'FILL:' "$S/standing-order.md" "$S/standing-order-impl.md" >&2; then
  echo "the standing order still has FILL markers: fill them in with the user" >&2
  exit 3
fi
[ -d "$REPO" ] || { echo "REPO in loop.env is no folder: $REPO" >&2; exit 1; }
# A tracked file would show as changed after the write and fail the gate.
if git -C "$REPO" ls-files --error-unmatch CLAUDE.local.md >/dev/null 2>&1; then
  echo "$REPO/CLAUDE.local.md is tracked by git: take it out of git first (git rm --cached), then run grant.sh again" >&2
  exit 1
fi
fill() {
  local text v LOOP=$S DATE USER
  DATE=$(date +%F) USER=$(id -un)
  text=$(<"$1")
  for v in LOOP IMPL DATE USER; do text=${text//"{{$v}}"/"${!v}"}; done
  printf '%s\n' "$text"
}
# put FILE TEMPLATE: append the order to FILE unless FILE already holds it.
put() {
  if has_grant "$1"; then echo "already in $1: left as it is (delete the order there to grant anew)"; return; fi
  { [ ! -s "$1" ] || echo >>"$1"; } && fill "$2" >>"$1" || { echo "cannot write $1: not granted there" >&2; exit 1; }
  echo "written: $1"
}
for f in standing-order.md standing-order-impl.md; do
  echo "----- $f"
  fill "$S/$f"
done
echo "-----"
echo "The first text goes into $S/CLAUDE.md, the second into $REPO/CLAUDE.local.md."
read -r -p "Is this your standing order for the loop's sessions? Type yes: " answer
[ "$answer" = yes ] || { echo "not granted, nothing written"; exit 1; }
for d in "$S" "$REPO"; do [ -w "$d" ] || { echo "cannot write into $d: nothing written" >&2; exit 1; }; done
put "$S/CLAUDE.md" "$S/standing-order.md"
put "$REPO/CLAUDE.local.md" "$S/standing-order-impl.md"
# An untracked file would fail the gate's clean-tree check.
if ex=$(git -C "$REPO" rev-parse --git-path info/exclude 2>/dev/null) &&
  ! git -C "$REPO" check-ignore -q CLAUDE.local.md; then
  case "$ex" in /*) ;; *) ex="$REPO/$ex" ;; esac
  mkdir -p "$(dirname "$ex")"
  [ ! -s "$ex" ] || [ -z "$(tail -c1 "$ex")" ] || echo >>"$ex"
  echo CLAUDE.local.md >>"$ex"
  git -C "$REPO" check-ignore -q CLAUDE.local.md || echo "CLAUDE.local.md is not ignored in $REPO: the gate's clean-tree check will fail until it is" >&2
fi
echo "granted. A session reads its instructions when it starts: start the implementer anew before the next brief."
