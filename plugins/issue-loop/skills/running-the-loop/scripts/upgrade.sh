#!/bin/bash
# usage: upgrade.sh <loop folder> [--apply]
# Brings a loop folder from copies of the scripts to the 0.9.0 shape: stubs for
# the scripts, the FILL answers in rules.local.md, ISSUE_LOOP_VERSION in
# loop.env. A dry run unless --apply. Old files go to before-upgrade/. Never
# touches CLAUDE.md, CLAUDE.local.md or the data files.
# Exit 2: no loop folder. Exit 1: refused, nothing written.
here=$(cd "$(dirname "$0")" && pwd -P)
PL="$here/../assets"
STUB="$here/stub.sh"
. "$PL/rules.sh"
STUBS="next.sh wait.sh gate.sh start.sh notify.sh grant.sh takeover-check.sh lib.sh"

[ -n "${1:-}" ] || { echo "usage: upgrade.sh <loop folder> [--apply]" >&2; exit 2; }
apply=0; [ "${2:-}" = --apply ] && apply=1
S=$(cd "$1" 2>/dev/null && pwd -P) || { echo "no such folder: $1" >&2; exit 2; }
[ -f "$S/loop.env" ] || { echo "no loop.env in $S: not a loop folder" >&2; exit 2; }
[ -f "$STUB" ] || { echo "no stub.sh beside upgrade.sh" >&2; exit 2; }
if [ -f "$S/rules.md" ] && [ -f "$S/rules.local.md" ]; then
  echo "$S has both rules.md and rules.local.md: move the old rules.md away, then run again" >&2
  exit 1
fi
steps=0 tmp=""

# The brief check runs first, so a refusal writes nothing.
if [ -f "$S/rules.md" ]; then
  tmp=$(mktemp) || exit 1
  extract_local "$PL/rules.md" "$S/rules.md" >"$tmp" || { echo "cannot read $S/rules.md" >&2; rm -f "$tmp"; exit 1; }
  if ! built=$(assemble_rules "$PL/rules.md" "$tmp") || [ "$built" != "$(cat "$S/rules.md")" ]; then
    echo "refused: the rules.local.md built from $S/rules.md would not rebuild it; nothing written" >&2
    [ -z "${built:-}" ] || diff "$S/rules.md" <(printf '%s\n' "$built") >&2
    rm -f "$tmp"; exit 1
  fi
fi

# act TEXT CMD...: prints the step as "would TEXT"; with --apply prints TEXT and runs CMD.
act() {
  local text=$1; shift
  steps=$((steps + 1))
  if [ $apply = 1 ]; then
    echo "$text"
    "$@" || { echo "failed: $text" >&2; exit 1; }
  else
    echo "would $text"
  fi
}

# put SRC DEST [x]: DEST gets SRC's bytes by a rename inside the folder, so a
# script still running keeps the inode it runs from.
put() {
  cat "$1" >"$S/.upgrade.tmp" || return 1
  [ -z "${3:-}" ] || chmod +x "$S/.upgrade.tmp"
  mv "$S/.upgrade.tmp" "$2"
}

# keep NAME: moves NAME in the folder to before-upgrade/NAME.
keep() {
  mkdir -p "$S/before-upgrade" && mv "$S/$1" "$S/before-upgrade/$1"
}

# stub_in NAME: the stub takes NAME's place; an old copy goes to before-upgrade/.
stub_in() {
  if [ -e "$S/$1" ]; then keep "$1" || return 1; fi
  put "$STUB" "$S/$1" x
}

# rules_in: rules.local.md from the checked text; the old rules.md goes to before-upgrade/.
rules_in() {
  put "$tmp" "$S/rules.local.md" && keep rules.md
}

# add_version: loop.env gets the version pin at its end.
add_version() {
  { cat "$S/loop.env"; printf '\n%s\n%s\n' "# Plugin version this loop runs: latest (the installed issue-loop), or an exact version such as 0.9.0 to roll back a bad release." "ISSUE_LOOP_VERSION=latest"; } >"$S/.upgrade.tmp" && mv "$S/.upgrade.tmp" "$S/loop.env"
}

for name in $STUBS; do
  if [ -f "$S/$name" ] && cmp -s "$S/$name" "$STUB" && [ -x "$S/$name" ]; then continue; fi
  if [ -e "$S/$name" ]; then
    act "replace $name with the stub (old copy to before-upgrade/$name)" stub_in "$name"
  else
    act "install stub $name" stub_in "$name"
  fi
done

if [ -e "$S/driver-herdr.sh" ]; then
  act "move driver-herdr.sh to before-upgrade/driver-herdr.sh (the plugin's copy runs now)" keep driver-herdr.sh
fi

if [ -f "$S/rules.md" ]; then
  act "write rules.local.md from rules.md (rules.md to before-upgrade/rules.md)" rules_in
fi

if ! grep -q '^ISSUE_LOOP_VERSION=' "$S/loop.env"; then
  act "add ISSUE_LOOP_VERSION=latest to loop.env" add_version
fi

if [ ! -f "$S/models.env" ]; then
  act "copy models.env from assets/ (check its values)" put "$PL/models.env" "$S/models.env"
fi

if [ $steps = 0 ]; then
  echo "nothing to change: $S is in the 0.9.0 shape"
  [ -z "$tmp" ] || rm -f "$tmp"
  exit 0
fi
if [ $apply = 1 ]; then
  echo "upgraded $S"
else
  if [ -n "$tmp" ]; then echo "rules.local.md it would write:"; cat "$tmp"; fi
  echo "dry run: nothing changed. Run again with --apply."
fi
[ -z "$tmp" ] || rm -f "$tmp"
exit 0
