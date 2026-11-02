# Tests that structure-hook runs no tool from a relative PATH entry: issue 327. Sourced by
# run.sh after hook.sh, which defines flags, and after fan-out.sh and hang.sh, whose helpers
# the rows from S10 on use. The tests of the cost limit of check-fan-out
# from S9 on sit here too, since the other files are near their size limit.

# Fills folder $1 with a fake of every tool on this machine, each noting in
# $CANARY that it ran. Faster than listing what the hook and checks may call.
fakes() {
  local tool
  mkdir -p "$1"
  # shellcheck disable=SC2016
  printf '#!/bin/sh\necho "$0" >>"%s"\nexit 0\n' "$CANARY" >"$1/.fake"
  chmod 755 "$1/.fake"
  for tool in /usr/bin/* /bin/* jq mise; do
    ln -sf .fake "$1/${tool##*/}"
  done
}

# Execs the hook itself, as Claude Code does, in folder $2 with PATH $1; sets RC, ERR.
# The event is for $REPO/.tools/big.md: a hidden folder, so fan-out skips the fakes.
run_with_path() {
  ERR="$(cd "$2" && printf '{"tool_input":{"file_path":"%s/.tools/big.md"}}' "$REPO" |
    PATH=$1 "$REPO/scripts/structure-hook" 2>&1 >/dev/null)"
  RC=$?
}

# Route $1, PATH $2, caller's folder $3 (default the edited file's folder).
no_repo_tool() {
  fresh
  CANARY="$WORK/canary$n"
  fakes .tools
  mkfile .tools/big.md 20004
  git -C "$REPO" config core.quotepath false
  run_with_path "$2" "${3:-$REPO/.tools}"
  if [ -e "$CANARY" ]; then
    bad "P1 $1: ran $(head -1 "$CANARY")"
  else
    ok "P1 $1: runs no repo tool"
  fi
  # With only "." the fallback path may hold no jq, and the hook says so.
  if { [ "$RC" -eq 2 ] && grep -q '^file-size: .*big.md ' <<<"$ERR"; } ||
    { [ "$2" = . ] && [ "$RC" -eq 1 ] && grep -q 'needs jq' <<<"$ERR"; }; then
    ok "P1 $1: file still checked"
  else
    bad "P1 $1: file still checked (rc=$RC: ${ERR:0:80})"
  fi
}

real=$PATH
no_repo_tool ". first" ".:$real"
no_repo_tool "empty entry first" ":$real"
no_repo_tool "empty entry between" "/nonexistent::$real"
no_repo_tool "empty entry last" "$real:"
no_repo_tool "only ." "."
no_repo_tool "./ first" "./:$real"
no_repo_tool ". first, called from another folder" ".:$real" "$WORK"
no_repo_tool "relative folder from the repo root" ".tools:$real" "$REPO"
no_repo_tool "../ entry" "../.tools:$real"

# With no jq on PATH the fallback runs mise in no project's folder: issue 334.
fresh
mkfile big.md 20004
tools="$WORK/tools$n"
mkdir -p "$tools" "$WORK/caller$n"
for t in /usr/bin/* /bin/*; do ln -sf "$t" "$tools/${t##*/}"; done
rm -f "$tools/jq" "$tools/mise"
jqbin="$(command -v jq)"
printf '#!/bin/sh\npwd >>"%s"\nshift 3\nexec "%s" "$@"\n' "$WORK/mise$n" "$jqbin" >"$tools/mise"
chmod 755 "$tools/mise"
ERR="$(cd "$WORK/caller$n" && printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
  PATH=$tools "$REPO/scripts/structure-hook" 2>&1 >/dev/null)"
RC=$?
ran="$(sort -u "$WORK/mise$n")"
if [ "$RC" -eq 2 ] && [ -n "$ran" ] && [ "${ran#"$REPO"}" = "$ran" ] && [ "${ran#"$WORK/caller"}" = "$ran" ]; then
  ok "P2 mise runs in neither the hook's folder nor the caller's"
else
  bad "P2 mise runs in neither the hook's folder nor the caller's (rc=$RC, ran in $ran)"
fi

# The mark the hook sets for itself, inherited from outside, changes nothing.
fresh
mkfile big.md 20004
ERR="$(printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
  STRUCTURE_HOOK_IN_BASH=1 "$REPO/scripts/structure-hook" 2>&1 >/dev/null)"
RC=$?
flags big.md "P3 an inherited STRUCTURE_HOOK_IN_BASH makes no false block"

# CDPATH must not send the hook's cd elsewhere: issue 331. The decoy's checks leave a mark.
decoy() {
  local d="$WORK/cdpath$n/$1"
  mkdir -p "$d"
  printf '#!/bin/sh\ntouch "%s"\n' "$WORK/decoy$n" >"$d/check-file-size"
  cp "$d/check-file-size" "$d/check-fan-out"
  chmod 755 "$d/check-file-size" "$d/check-fan-out"
}
fresh
mkfile big.md 20004
decoy scripts
ERR="$(printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
  CDPATH="$WORK/cdpath$n" scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
flags big.md "S2 CDPATH with a relative \$0: file still checked"
if [ -e "$WORK/decoy$n" ]; then bad "S2 CDPATH with a relative \$0: decoy ran"; else ok "S2 CDPATH with a relative \$0: decoy stays out"; fi

fresh
mkfile sub/big.md 20004
decoy sub
ERR="$(printf '{"tool_input":{"file_path":"sub/big.md"}}' |
  CDPATH="$WORK/cdpath$n" scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
flags sub/big.md "S3 CDPATH with a relative file_path: file still checked"

# The limit of issue 328: an absolute entry inside the edited repo is the user's
# own setting, so it stays, and its tool runs. See references/editor-hook.md.
fresh
mkfile big.md 20004
mkdir -p .tools
awkbin="$(command -v awk)"
printf '#!/bin/sh\ntouch "%s"\nexec "%s" "$@"\n' "$WORK/mark$n" "$awkbin" >.tools/awk
chmod 755 .tools/awk
run_with_path_big() {
  ERR="$(printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
    PATH=$1 "$REPO/scripts/structure-hook" 2>&1 >/dev/null)"
  RC=$?
}
run_with_path_big "$REPO/.tools:$real"
flags big.md "P4 absolute entry inside the repo: file still checked"
if [ -e "$WORK/mark$n" ]; then ok "P4 absolute entry inside the repo: its tool runs, the documented limit"; else bad "P4 absolute entry inside the repo: its tool runs, the documented limit"; fi

# S9 348: a plain "**" that ends a glob costs a folder nothing per byte of its path, so
# a big repo under one such line does not reach the limit on matching. Entries go in
# the index only, since the check reads names from git.
fresh
long=$(printf '%0.sabcdefghi/' $(seq 380))
for i in $(seq 5000); do
  for f in 1 2 3 4 5 6 7 8; do printf '100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tv/%s%s/f%s\n' "$long" "$i" "$f"; done
done | git update-index --index-info
echo 'v/**' >.fan-out-excludes
ERR="$(timeout 60 bash scripts/check-fan-out --all 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 0 ]; then ok "S9 348: v/** over 5000 long folders passes"; else bad "S9 348: v/** over 5000 long folders passes (rc=$RC: ${ERR:0:100})"; fi

# S10 350: the filter charges a glob it rejects past its fourth plain text. 1024 lines of
# 127 plain texts and "zz*", on folders that hold all 127 but no "zz", ran 16 to 43 s and
# reported the folders; each rejection now costs 128 steps, so the run stops. A "fan-out:"
# line counts as a failure, whatever the exit code.
all=$(printf '%03d' $(seq 127))
glob="$(printf '%03d*' $(seq 127))zz*"
built_folders() {
  local i f
  fresh
  for i in $(seq "$1"); do
    for f in 1 2 3 4 5 6 7 8; do printf '100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\t%s%s/f%s\n' "$all" "$i" "$f"; done
  done | git update-index --index-info
  yes "$glob" | head -n 1024 >.fan-out-excludes
}
built_folders 500
for aw in "${UNDER[@]}"; do
  ERR="$(PATH=$WORK/under-${aw%% *}:$PATH timeout 120 bash scripts/check-fan-out --all 2>&1 >/dev/null)"
  RC=$?
  grep -q '^fan-out:' <<<"$ERR" && RC=reported
  want_rc "S10 350 $aw: many plain texts over 500 folders stop" 2
done

# S10 the charge makes no false stop: over 20 folders the same lines spend 1.4 million.
built_folders 20
for aw in "${UNDER[@]}"; do
  fan_under "$aw"
  got=$(grep -c '^fan-out: ' <<<"$ERR")
  if [ "$RC" -eq 1 ] && [ "$got" -eq 20 ]; then ok "S10 350 $aw: the same lines over 20 folders report them all"; else bad "S10 350 $aw: the same lines over 20 folders report them all (rc=$RC, $got)"; fi
done

# S11 350: what a stop does, with the limit cut to one step so that it comes at once.
stop_line='check-fan-out: .fan-out-excludes costs too much to match here. Use fewer globs or fewer wildcards in a glob.'
stops_alone() {
  if [ "$RC" -eq 2 ] && [ "$ERR" = "$stop_line" ]; then ok "$1"; else bad "$1 (rc=$RC: ${ERR:0:120})"; fi
}
for aw in "${UNDER[@]}"; do
  fresh
  sed -i 's/16000000/1/' scripts/check-fan-out
  files 8 abcd
  git add -A
  fan_excludes 'a*b*c?'
  under=$WORK/under-${aw%% *}:$PATH
  fan_under "$aw"
  stops_alone "S11 350 $aw: a stop prints its line and reports no folder"
  ERR="$(PATH=$under timeout 10 bash scripts/check-fan-out abcd/a1 2>&1 >/dev/null)"
  RC=$?
  stops_alone "S11 350 $aw: a stop on a path run prints its line alone"
  ERR="$(PATH=$under timeout 10 bash scripts/check-fan-out --update-baseline 2>&1 >/dev/null)"
  RC=$?
  stops_alone "S11 350 $aw: a stop on --update-baseline prints its line alone"
  if [ ! -e .fan-out-baseline ]; then ok "S11 350 $aw: a stop writes no new baseline"; else bad "S11 350 $aw: a stop writes no new baseline"; fi
  printf '%s\n' '# kept' 'abcd 9' 'gone 9' >.fan-out-baseline
  cp .fan-out-baseline "$WORK/baseline$n"
  ERR="$(PATH=$under timeout 10 bash scripts/check-fan-out --update-baseline 2>&1 >/dev/null)"
  RC=$?
  stops_alone "S11 350 $aw: a stop on --update-baseline with a file prints its line alone"
  if cmp -s .fan-out-baseline "$WORK/baseline$n"; then ok "S11 350 $aw: a stop leaves the baseline as it was"; else bad "S11 350 $aw: a stop leaves the baseline as it was"; fi
  PATH=$under try_hook "$REPO/abcd/a1"
  stops_alone "S11 350 $aw: the hook shows a stop with exit 2"
done
