# Tests that structure-hook runs no tool from a relative PATH entry: issue 327.
# Sourced by run.sh after hook.sh, which defines flags.

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

# With no jq on PATH the fallback runs mise in the hook's folder, not the caller's.
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
if [ "$RC" -eq 2 ] && [ "$(sort -u "$WORK/mise$n")" = "$REPO/scripts" ]; then
  ok "P2 mise runs from the hook's folder"
else
  bad "P2 mise runs from the hook's folder (rc=$RC, ran in $(cat "$WORK/mise$n" 2>/dev/null))"
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
