# Tests of how structure-hook gets its event and its tools: issues 334, 335, 332.
# Sourced by run.sh after hook.sh and hang.sh, which define flags, plant, returns.

# Feeds the hook the event for path $1 with PATH $2 (default the current one) from
# the current folder, as Claude Code does; sets RC, ERR.
event() {
  ERR="$(jq -cn --arg f "$1" '{tool_input: {file_path: $f}}' |
    PATH=${2:-$PATH} timeout 20 scripts/structure-hook 2>&1 >/dev/null)"
  RC=$?
}
jqbin="$(command -v jq)"
jqdir="$(dirname "$(readlink -f "$jqbin")")"
base=/usr/bin:/bin

# The issue's steps: the repo names its own jq, which leaves a mark, in file $1
# holding line $2. The real mise and a shim of it in a folder of our own.
if realmise="$(readlink -f "$(command -v mise)")" && [ -x "$realmise" ]; then
  mise_route() {
    local data="$WORK/data$n"
    fresh
    data="$WORK/data$n"
    mkfile big.md 20004
    mkdir -p evil "$data/shims"
    printf '#!/bin/sh\ntouch "%s"\nexec "%s" "$@"\n' "$WORK/mark$n" "$jqbin" >evil/jq
    chmod 755 evil/jq
    printf '%s\n' "$2" >"$1"
    ln -s "$realmise" "$data/shims/jq"
    ln -s "$realmise" "$data/shims/git"
    export MISE_DATA_DIR=$data MISE_GLOBAL_CONFIG_FILE=$WORK/global$n.toml
    : >"$MISE_GLOBAL_CONFIG_FILE"
    if [ -n "${3:-}" ]; then printf '[tools]\njq = "path:%s"\n' "$jqdir" >"$MISE_GLOBAL_CONFIG_FILE"; fi
    event "$REPO/big.md" "$data/shims:$base"
    unset MISE_DATA_DIR MISE_GLOBAL_CONFIG_FILE
    if [ -e "$WORK/mark$n" ]; then bad "M1 $1: the repo's jq ran"; else ok "M1 $1: the repo's jq did not run"; fi
  }
  # Only jq in /usr/bin would change what these expect, so skip on such a machine.
  if [ ! -x /usr/bin/jq ] && [ ! -x /bin/jq ]; then
    for route in ".tool-versions|jq path:./evil" 'mise.toml|[tools]
jq = "path:./evil"'; do
      mise_route "${route%%|*}" "${route#*|}"
      if [ "$RC" -eq 1 ] && grep -q 'needs jq' <<<"$ERR"; then ok "M2 ${route%%|*}, jq in no global config: exit 1, says so"; else bad "M2 ${route%%|*}, jq in no global config: exit 1, says so (rc=$RC: ${ERR:0:120})"; fi
      mise_route "${route%%|*}" "${route#*|}" global
      flags big.md "M3 ${route%%|*}, jq in the global config: mise found through the shim, file checked"
    done
  fi
else
  echo "skip M1 to M3: no mise"
fi

# The shim folder goes by its usual name, with or without the last "/", and by
# MISE_DATA_DIR. A shim there that runs leaves a mark.
for route in "xdg/mise/shims" "xdg/mise/shims/" "custom/shims"; do
  fresh
  mkfile big.md 20004
  shims="$WORK/s$n/$route"
  mkdir -p "$shims"
  printf '#!/bin/sh\ntouch "%s"\n' "$WORK/mark$n" >"$shims/awk"
  chmod 755 "$shims/awk"
  case $route in custom/*) export MISE_DATA_DIR=$WORK/s$n/custom ;; esac
  event "$REPO/big.md" "$shims:$PATH"
  unset MISE_DATA_DIR
  flags big.md "M4 shim folder $route: file checked"
  if [ -e "$WORK/mark$n" ]; then bad "M4 shim folder $route: a shim ran"; else ok "M4 shim folder $route: no shim ran"; fi
done

# With git only as a shim the file must not pass in silence.
fresh
mkfile big.md 20004
tools="$WORK/tools$n"
mkdir -p "$tools"
for t in /usr/bin/* /bin/*; do ln -sfn "$t" "$tools/${t##*/}"; done
rm -f "$tools/git"
ln -sf "$jqbin" "$tools/jq"
event "$REPO/big.md" "$tools"
if [ "$RC" -eq 1 ] && grep -q 'needs git' <<<"$ERR"; then ok "M5 no git on PATH: exit 1, says so"; else bad "M5 no git on PATH: exit 1, says so (rc=$RC: ${ERR:0:120})"; fi

# A jq that fails: issue 335, part 1. The event goes in by hand, as this jq cannot.
fresh
mkfile big.md 20004
tools="$WORK/tools$n"
mkdir -p "$tools"
printf '#!/bin/sh\necho no version >&2\nexit 127\n' >"$tools/jq"
chmod 755 "$tools/jq"
ERR="$(printf '{"tool_input":{"file_path":"%s/big.md"}}' "$REPO" |
  PATH="$tools:$PATH" scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -q 'needs jq' <<<"$ERR"; then ok "E1 jq fails: exit 1, says so"; else bad "E1 jq fails: exit 1, says so (rc=$RC: ${ERR:0:120})"; fi

fresh
ERR="$(printf 'not json' | scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -q 'needs jq' <<<"$ERR"; then ok "E1 an event jq cannot read: exit 1, says so"; else bad "E1 an event jq cannot read: exit 1, says so (rc=$RC: ${ERR:0:120})"; fi

# A name ending in a newline: part 2.
fresh
name=$'big.md\n'
mkfile "$name" 20004
event "$REPO/$name"
if [ "$RC" -eq 2 ] && grep -qF 'is ~5001 tokens' <<<"$ERR"; then ok "E2 name ending in a newline is reported"; else bad "E2 name ending in a newline is reported (rc=$RC: ${ERR:0:120})"; fi
fresh
mkfile sub/$'big\n\n' 20004
event "sub/"$'big\n\n'
if [ "$RC" -eq 2 ] && grep -qF 'is ~5001 tokens' <<<"$ERR"; then ok "E2 relative name ending in two newlines is reported"; else bad "E2 relative name ending in two newlines is reported (rc=$RC: ${ERR:0:120})"; fi

# Names that read as options: part 3, with folders of the same kind.
for path in --help -dash.md -x/big.md -/big.md; do
  fresh
  mkfile "./$path" 20004
  event "$path"
  flags "$path" "E3 relative $path is reported"
  if grep -qE '^(dirname|basename|cd|Usage)' <<<"$ERR"; then bad "E3 relative $path: stray error (${ERR:0:80})"; else ok "E3 relative $path: nothing beside the report"; fi
done

# A small one of them passes in silence, and a file_path that is no string passes.
fresh
mkfile ./--help 1
event --help
silent "E3 small --help passes"
fresh
ERR="$(printf '{"tool_input":{"file_path":12}}' | scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
silent "E4 a number as file_path passes"


# The give-up line names an odd file too.
fresh
mkfile ./-x/big.md 20004
plant .gitignore fifo
short_limit
event -x/big.md
if [ "$RC" -eq 1 ] && grep -qF 'gave up on -x/big.md after 1 s' <<<"$ERR"; then ok "E6 give-up names -x/big.md"; else bad "E6 give-up names -x/big.md (rc=$RC: ${ERR:0:120})"; fi

# Stdin open with no end: issue 332. A FIFO, so that no pipeline waits for the writer.
fresh
short_limit
HANG_TMP="$WORK/tmp$n"
mkdir -p "$HANG_TMP"
mkfifo "$WORK/in$n"
sleep 60 >"$WORK/in$n" &
writer=$!
ERR="$(TMPDIR="$HANG_TMP" timeout 10 scripts/structure-hook 2>&1 >/dev/null <"$WORK/in$n")"
RC=$?
kill "$writer" 2>/dev/null
wait "$writer" 2>/dev/null
if [ "$RC" -eq 1 ] && grep -qF 'gave up on the edited file after 1 s' <<<"$ERR"; then ok "S4 stdin open with no end: gives up"; else bad "S4 stdin open with no end: gives up (rc=$RC: ${ERR:0:120})"; fi
returns "S4 stdin open with no end: returns, no temp files"

# Stdin that never ends: the read stops at its cap, far under the job's limit.
fresh
HANG_TMP="$WORK/tmp$n"
mkdir -p "$HANG_TMP"
ERR="$(yes | TMPDIR="$HANG_TMP" timeout 25 scripts/structure-hook 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -q 'needs jq' <<<"$ERR"; then ok "S5 stdin that never ends: exit 1"; else bad "S5 stdin that never ends: exit 1 (rc=$RC: ${ERR:0:120})"; fi
returns "S5 stdin that never ends: returns, no temp files"

# Empty stdin that closes: no event, nothing to say.
fresh
ERR="$(scripts/structure-hook 2>&1 >/dev/null </dev/null)"
RC=$?
silent "S6 empty stdin passes"

# The read in the job still hands the event to the check.
fresh
mkfile big.md 20004
event "$REPO/big.md"
flags big.md "S7 a plain event is still read"
