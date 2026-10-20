#!/bin/bash
# usage: init.sh <loop folder>
# Makes a loop folder of data only: the templates, HANDOFF.md, and one stub
# under each script name (scripts/stub.sh). The scripts run from the installed
# plugin. Refuses a folder inside a git checkout (the loop folder must not sit in
# the implementer's checkout) and never overwrites a file that is already there.
set -eu
dir=${1:?usage: init.sh <loop folder>}
here=$(cd "$(dirname "$0")/.." && pwd)
STUBS="next.sh wait.sh gate.sh start.sh notify.sh grant.sh takeover-check.sh lib.sh"
# Check before making anything: look at the nearest folder that exists.
at=$dir
while [ ! -d "$at" ]; do at=$(dirname "$at"); done
if git -C "$at" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$dir is inside a git checkout: pick a folder outside every checkout" >&2
  exit 1
fi
mkdir -p "$dir"
for f in loop.env models.env ledger.tsv standing-order.md standing-order-impl.md rules.local.md; do
  [ -e "$dir/$f" ] || cp "$here/assets/$f" "$dir/"
done
[ -f "$dir/HANDOFF.md" ] || cp "$here/../handing-over/references/handoff-template.md" "$dir/HANDOFF.md"
for n in $STUBS; do
  [ -e "$dir/$n" ] || cp "$here/scripts/stub.sh" "$dir/$n"
  chmod +x "$dir/$n"
done
echo "loop folder ready: $dir"
echo "next: edit loop.env, answer the FILL markers in rules.local.md, fill HANDOFF.md,"
echo "write the orchestrator's session name into orch-name, and have the user start claude once in $dir to trust the folder."
echo "Then fill standing-order.md with the user, read standing-order-impl.md with them, and have the user run $dir/grant.sh in a terminal of their own."
