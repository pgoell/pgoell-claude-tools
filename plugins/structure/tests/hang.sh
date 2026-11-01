# Tests that structure-hook returns on a repo whose files block or never end, and
# leaves nothing running: issue 326. Sourced by run.sh after hook.sh.

# Makes path $1 of kind $2: zero, urandom (symlinks to the device) or fifo.
plant() {
  mkdir -p "$(dirname "$1")"
  rm -rf "$1"
  case $2 in
    fifo) mkfifo "$1" ;;
    *) ln -s "/dev/$2" "$1" ;;
  esac
}

# Runs the hook on big.md (or $1) with its own TMPDIR; sets RC, ERR. A blocked
# hook meets the outer timeout, 124. The test's cap catches memory growth.
try_hook() {
  HANG_TMP="$WORK/tmp$n"
  mkdir -p "$HANG_TMP"
  ERR="$(
    ulimit -v 4194304
    printf '{"tool_input":{"file_path":"%s"}}' "${1:-$REPO/big.md}" |
      TMPDIR="$HANG_TMP" timeout 10 bash scripts/structure-hook 2>&1 >/dev/null
  )"
  RC=$?
}

# The file must still be checked, in its plain report: no memory error, no hang.
still_checks() {
  if [ "$RC" -eq 2 ] && grep -q '^file-size: big.md ' <<<"$ERR" && ! grep -qiE 'fatal|memory|error' <<<"$ERR"; then
    ok "$1"
  else
    bad "$1 (rc=$RC: ${ERR:0:80})"
  fi
}

# The hook must return by itself, by any exit, and leave no temp files.
returns() {
  local left
  left="$(ls -A "$HANG_TMP")"
  if [ "$RC" -ne 124 ] && [ -z "$left" ]; then ok "$1"; else bad "$1 (rc=$RC left=$left)"; fi
}

# Limit 1 s for the FIFOs git opens, which only the job can end.
short_limit() { sed -i 's/^limit=30$/limit=1/' scripts/structure-hook; }

# The checks' own settings: each kind is skipped at once, and the file is checked.
for path in .fan-out-excludes .fan-out-baseline .file-size-excludes .git/info/exclude; do
  for kind in zero urandom fifo; do
    fresh
    mkfile big.md 20004
    plant "$path" "$kind"
    try_hook
    still_checks "G1 $path as $kind: file still checked"
    returns "G1 $path as $kind: returns"
  done
done

# The same files, regular but huge: no cap would mean gigabytes of memory.
for path in .fan-out-excludes .fan-out-baseline .file-size-excludes .git/info/exclude; do
  fresh
  mkfile big.md 20004
  mkdir -p .git/info
  truncate -s 100G "$path"
  try_hook
  still_checks "G2 sparse 100G $path: file still checked"
done

# What git opens in the work tree, as a FIFO: the job ends it, and says so.
for path in .gitignore .gitattributes sub/.gitignore sub/.gitattributes other/.gitignore; do
  fresh
  mkfile sub/big.md 20004
  plant "$path" fifo
  short_limit
  try_hook "$REPO/sub/big.md"
  if [ "$RC" -eq 1 ] && grep -q '^structure-hook: gave up on .*sub/big.md after 1 s' <<<"$ERR"; then
    ok "G3 $path as a FIFO: gives up with a message"
  else
    bad "G3 $path as a FIFO: gives up with a message (rc=$RC: ${ERR:0:80})"
  fi
  returns "G3 $path as a FIFO: no temp files"
done

# Git does not follow these symlinks.
for path in .gitignore .gitattributes sub/.gitignore; do
  for kind in zero urandom; do
    fresh
    mkfile big.md 20004
    plant "$path" "$kind"
    try_hook
    still_checks "G4 $path as $kind: file still checked"
  done
done

# What git reads to find the repo, and a nested repo's files on its walk.
for path in .git/config .git/HEAD .git/commondir nested/.git nested/.git/HEAD; do
  for kind in zero urandom fifo; do
    fresh
    mkfile big.md 20004
    if [ "${path#nested/.git/}" != "$path" ]; then mkdir -p nested/.git/objects nested/.git/refs; fi
    plant "$path" "$kind"
    short_limit
    try_hook
    returns "G5 $path as $kind: returns"
  done
done
for kind in zero fifo; do
  fresh
  mkfile big.md 20004
  plant .git "$kind"
  short_limit
  try_hook
  returns "G5 .git as $kind: returns"
done

# A bare-style folder in a clone, whose config a symlink can point anywhere.
for kind in zero urandom; do
  fresh
  mkdir -p evil/objects evil/refs
  echo 'ref: refs/heads/master' >evil/HEAD
  mkfile evil/note.md 20004
  plant evil/config "$kind"
  short_limit
  try_hook "$REPO/evil/note.md"
  returns "G5 bare-style folder with config as $kind: returns"
done

# A sparse .gitignore: git would read it all, so the memory cap stops git.
fresh
mkfile big.md 20004
truncate -s 5G .gitignore
HANG_TMP="$WORK/tmp$n"
mkdir -p "$HANG_TMP"
ERR="$(printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
  TMPDIR="$HANG_TMP" timeout 30 bash scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "G6 sparse 5G .gitignore: git stops at the cap"; else bad "G6 sparse 5G .gitignore: git stops at the cap (rc=$RC)"; fi

# Lists the processes whose current folder is $REPO or below; Linux only.
in_repo() {
  local p
  for p in /proc/[0-9]*; do
    case "$(readlink "$p/cwd" 2>/dev/null)" in "$REPO" | "$REPO"/*) echo "${p#/proc/}" ;; esac
  done
}

# Starts the hook, waits until something of it runs in the repo, sends SIGTERM to
# the hook's bash, and expects nothing of it left and no temp files.
term_leaves_nothing() {
  local pid
  cd "$WORK" || exit 1
  HANG_TMP="$WORK/tmp$n"
  mkdir -p "$HANG_TMP"
  printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" >"$WORK/event$n"
  (cd "$WORK" && exec env TMPDIR="$HANG_TMP" bash "$REPO/scripts/structure-hook" <"$WORK/event$n" >/dev/null 2>&1) &
  pid=$!
  for _ in $(seq 100); do
    [ -z "$(in_repo)" ] || break
    sleep 0.1
  done
  if [ -z "$(in_repo)" ]; then
    bad "$1: never started"
    kill -9 "$pid" 2>/dev/null
    return
  fi
  sleep 0.5
  kill -TERM "$pid"
  wait "$pid" 2>/dev/null
  for _ in $(seq 30); do
    [ -n "$(in_repo)" ] || break
    sleep 0.1
  done
  local left
  left="$(in_repo)"
  if [ -z "$left" ] && [ -z "$(ls -A "$HANG_TMP")" ]; then
    ok "$1"
  else
    bad "$1 (left: $left $(ls -A "$HANG_TMP"))"
    # shellcheck disable=SC2086
    [ -z "$left" ] || kill -9 $left 2>/dev/null
  fi
}

if [ -d /proc/self ]; then
  for path in .gitignore .gitattributes sub/.gitignore; do
    fresh
    mkfile big.md 20004
    plant "$path" fifo
    term_leaves_nothing "G7 SIGTERM with $path as a FIFO: nothing left running"
  done
  # A check that is slow, not blocked in git.
  fresh
  mkfile big.md 20004
  sed -i 's|^tr .*|sleep 60 \&\& &|' scripts/check-fan-out
  term_leaves_nothing "G7 SIGTERM during a slow check: nothing left running"

  # A plain run: the job with its sleep ends with the hook.
  fresh
  mkfile big.md 20004
  cd "$WORK" || exit 1
  caller="$WORK/caller$n"
  mkdir "$caller"
  printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" | (cd "$caller" && exec bash "$REPO/scripts/structure-hook") >/dev/null 2>&1
  REPO=$caller
  if [ -z "$(in_repo)" ]; then ok "G8 the hook's job ends with the hook"; else bad "G8 the hook's job ends with the hook"; fi
fi
