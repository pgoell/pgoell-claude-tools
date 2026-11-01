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

# Every git the hook starts runs under the memory cap: review of PR 329, where a
# symlink at .git/commondir filled memory in the first git, before the cap.
fresh
mkfile big.md 20004
tools="$WORK/tools$n"
mkdir -p "$tools"
gitbin="$(command -v git)"
# shellcheck disable=SC2016
printf '#!/bin/sh\nulimit -v >>"%s"\nexec "%s" "$@"\n' "$WORK/caps$n" "$gitbin" >"$tools/git"
chmod 755 "$tools/git"
PATH="$tools:$PATH" hook "$REPO/big.md"
if [ "$(sort -u "$WORK/caps$n")" = 4194304 ]; then ok "G6 every git runs under the memory cap"; else bad "G6 every git runs under the memory cap ($(sort -u "$WORK/caps$n" | tr '\n' ' '))"; fi

# A setting nobody may read counts as absent, not as a failed check: review of PR 329.
for path in .fan-out-excludes .fan-out-baseline .file-size-excludes .git/info/exclude; do
  fresh
  mkfile small.md 1
  ln -sf /proc/self/mem "$path"
  try_hook "$REPO/small.md"
  silent "G9 $path as a link to /proc/self/mem passes"
  fresh
  mkfile small.md 1
  mkdir -p .git/info
  : >"$path"
  chmod 000 "$path"
  try_hook "$REPO/small.md"
  silent "G9 unreadable $path passes"
done

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
  sed -i 's|^while IFS= read -r -d .* path; do|sleep 60 \&\& &|' scripts/check-fan-out
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

# With stdin closed the hook has no event, and returns without one: issue 330.
fresh
HANG_TMP="$WORK/tmp$n"
mkdir -p "$HANG_TMP"
ERR="$(TMPDIR="$HANG_TMP" timeout 10 scripts/structure-hook 2>&1 >/dev/null <&-)"
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "S1 closed stdin: exits 0 and says nothing"; else bad "S1 closed stdin: exits 0 and says nothing (rc=$RC: ${ERR:0:80})"; fi
returns "S1 closed stdin: returns"

# Runs the hook with jq only through the fake mise $1, on big.md with a FIFO
# .gitignore, so the job gives up. Sets RC, ERR.
give_up_with_mise() {
  local t tools
  fresh
  tools="$WORK/tools$n"
  mkfile big.md 20004
  plant .gitignore fifo
  short_limit
  mkdir -p "$tools"
  for t in /usr/bin/* /bin/*; do ln -sfn "$t" "$tools/${t##*/}"; done
  rm -f "$tools/jq" "$tools/mise"
  printf '#!/bin/sh\n%s\n' "$1" >"$tools/mise"
  chmod 755 "$tools/mise"
  ERR="$(printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
    PATH=$tools timeout 10 scripts/structure-hook 2>&1 >/dev/null)"
  RC=$?
}

# The give-up line names the file, wherever jq came from.
give_up_with_mise "shift 3; exec \"$(command -v jq)\" \"\$@\""
if [ "$RC" -eq 1 ] && grep -qF "gave up on $REPO/big.md after 1 s" <<<"$ERR"; then ok "G10 jq only through mise: give-up names the file"; else bad "G10 jq only through mise: give-up names the file (rc=$RC: ${ERR:0:120})"; fi
fresh
mkfile big.md 20004
plant .gitignore fifo
short_limit
try_hook
if [ "$RC" -eq 1 ] && grep -qF "gave up on $REPO/big.md after 1 s" <<<"$ERR"; then ok "G10 jq on PATH: give-up names the file"; else bad "G10 jq on PATH: give-up names the file (rc=$RC: ${ERR:0:120})"; fi

# A mise that blocks: the name is not known yet, and the line leaves no blank.
give_up_with_mise "exec sleep 60"
if [ "$RC" -eq 1 ] && grep -qF "gave up on the edited file after 1 s" <<<"$ERR"; then ok "G11 mise blocks: give-up says the edited file"; else bad "G11 mise blocks: give-up says the edited file (rc=$RC: ${ERR:0:120})"; fi

# Writes $2 copies of character $1 to stdout.
repeat() { head -c "$2" /dev/zero | tr '\0' "$1"; }

# L1 a 1 MiB excludes line of backslashes costs no real time: issue 340.
fresh
mkfile small.md 100
git add -A
repeat '\' 1048576 >.file-size-excludes
timeout 10 bash scripts/check-file-size small.md >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then ok "L1 a 1 MiB excludes line does not stall"; else bad "L1 a 1 MiB excludes line does not stall (rc=$RC)"; fi

# L2 a line over the kernel's 128 KiB limit for one argument does not reach git.
fresh
mkfile small.md 100
git add -A
repeat a 200000 >.file-size-excludes
run small.md
if passes; then ok "L2 a 200 KB excludes line does not fail the check"; else bad "L2 a 200 KB excludes line does not fail the check (rc=$RC: ${ERR:0:200})"; fi

# L3 both checks keep a line of 512 bytes and skip one of 513.
for size in 512 513; do
  fresh
  mkfile big.md 20004
  files 8 src
  git add -A
  { repeat '*' $((size - 6)) && echo big.md; } >.file-size-excludes
  { repeat '*' $((size - 3)) && echo src; } >.fan-out-excludes
  run big.md
  size_rc=$RC
  fan --all
  want=$((size == 512 ? 0 : 1))
  if [ "$size_rc" -eq "$want" ] && [ "$RC" -eq "$want" ]; then
    ok "L3 both checks treat a line of $size bytes alike"
  else
    bad "L3 both checks treat a line of $size bytes alike (file-size rc=$size_rc, fan-out rc=$RC)"
  fi
done

# L4 a skipped line hides nothing: the big file it named still fails the check.
fresh
mkfile big.md 20004
git add -A
{ printf 'big.md' && repeat ' ' 200000; } >.file-size-excludes
ERR=$(timeout 10 bash scripts/check-file-size big.md 2>&1 >/dev/null)
RC=$?
if [ "$RC" -eq 1 ] && reports big.md; then ok "L4 a skipped line leaves its file reported"; else bad "L4 a skipped line leaves its file reported (rc=$RC: ${ERR:0:200})"; fi

# L5 both checks measure the line as written, spaces and all.
fresh
mkfile big.md 20004
files 8 src
git add -A
{ repeat ' ' 600 && echo big.md; } >.file-size-excludes
{ repeat ' ' 600 && echo src; } >.fan-out-excludes
run big.md
size_rc=$RC
fan --all
if [ "$size_rc" -eq 1 ] && [ "$RC" -eq 1 ]; then
  ok "L5 both checks skip a line padded past 512 bytes"
else
  bad "L5 both checks skip a line padded past 512 bytes (file-size rc=$size_rc, fan-out rc=$RC)"
fi

# L6 the most the skip lets through: 1 MiB of lines at the limit. A guard, as master
# passes it too.
for ch in '\' ' ' a; do
  fresh
  mkfile small.md 100
  git add -A
  yes "$(repeat "$ch" 512)" | head -c 1048576 >.file-size-excludes
  timeout 10 bash scripts/check-file-size small.md >/dev/null 2>&1
  RC=$?
  if [ "$RC" -eq 0 ]; then ok "L6 1 MiB of 512-byte lines of '$ch' pass in time"; else bad "L6 1 MiB of 512-byte lines of '$ch' pass in time (rc=$RC)"; fi
done
