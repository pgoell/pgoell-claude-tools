#!/bin/bash
# usage: init.sh <loop folder>
# Copies the loop's templates into a new folder. Refuses a folder inside a git
# checkout (the loop folder must not sit in the implementer's checkout) and
# never overwrites a file that is already there.
set -eu
dir=${1:?usage: init.sh <loop folder>}
here=$(cd "$(dirname "$0")/.." && pwd)
# Check before making anything: look at the nearest folder that exists.
at=$dir
while [ ! -d "$at" ]; do at=$(dirname "$at"); done
if git -C "$at" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$dir is inside a git checkout: pick a folder outside every checkout" >&2
  exit 1
fi
mkdir -p "$dir"
for f in "$here"/assets/*; do
  [ -e "$dir/$(basename "$f")" ] || cp "$f" "$dir/"
done
[ -f "$dir/HANDOFF.md" ] || cp "$here/../handing-over/references/handoff-template.md" "$dir/HANDOFF.md"
chmod +x "$dir"/next.sh "$dir"/wait.sh "$dir"/gate.sh "$dir"/start.sh
echo "loop folder ready: $dir"
echo "next: edit loop.env, fill the FILL markers in rules.md, fill HANDOFF.md,"
echo "and have the user start claude once in $dir to trust the folder"
