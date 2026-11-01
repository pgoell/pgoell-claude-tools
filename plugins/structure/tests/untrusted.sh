# Tests that structure-hook runs no code from the repo of an edited file: issue
# 324. Sourced by run.sh after hook.sh, which defines hook, flags, silent, objects.

# Makes a repo with an over-limit big.md and a canary script $PWN, which notes in
# $CANARY that it ran. Sets $TRACE, the git trace of the hook's run.
armed() {
  fresh
  mkfile big.md 20004
  CANARY="$WORK/canary$n"
  TRACE="$WORK/trace$n"
  PWN="$REPO/.git/pwn.sh"
  printf '#!/bin/sh\necho ran >>"%s"\ncat\n' "$CANARY" >"$PWN"
  chmod 755 "$PWN"
}

# Expects, for route name $1, that the file at path $2 (default $REPO/big.md) is
# checked by its report line $3 (default big.md), that the canary did not run,
# and that no git the hook started spawned anything.
no_code() {
  GIT_TRACE="$TRACE" hook "${2:-$REPO/big.md}" "$REPO/scripts/structure-hook"
  flags "${3:-big.md}" "U1 $1: file still checked"
  if [ -e "$CANARY" ]; then bad "U1 $1: repo's code ran"; else ok "U1 $1: repo's code did not run"; fi
  if grep -q 'run_command' "$TRACE"; then
    bad "U1 $1: git spawned $(grep -m1 'run_command' "$TRACE")"
  else
    ok "U1 $1: git spawned nothing"
  fi
}

# An unpacked archive holds any .git it likes, so each route writes it directly.
armed
git config core.fsmonitor "$PWN"
no_code "core.fsmonitor"

armed
echo 'big.md filter=p' >.gitattributes
git config filter.p.clean "$PWN"
no_code "filter clean"

armed
echo 'big.md filter=p' >.gitattributes
git config filter.p.process "$PWN"
no_code "filter process"

armed
mkdir "$REPO/.git/h"
cp "$PWN" "$REPO/.git/h/post-index-change"
git config core.hooksPath "$REPO/.git/h"
no_code "core.hooksPath"

armed
mkdir -p "$REPO/.git/hooks"
cp "$PWN" "$REPO/.git/hooks/post-index-change"
no_code "hook in .git/hooks"

armed
git config --file "$REPO/.git/extra" core.fsmonitor "$PWN"
git config include.path extra
no_code "include.path"

armed
git config extensions.worktreeConfig true
git config --worktree core.fsmonitor "$PWN"
no_code "config.worktree"

# A partial clone fetches an object it lacks, here for a file git trusts by its
# stat data, and the fetch runs the repo's core.sshCommand.
armed
touch -d '1 minute ago' big.md
git add big.md
sha="$(git ls-files -s big.md | cut -d' ' -f2)"
rm -f ".git/objects/${sha:0:2}/${sha:2}"
git config core.repositoryformatversion 1
git config extensions.partialClone origin
git config remote.origin.url ssh://example.invalid/x
git config remote.origin.promisor true
git config core.sshCommand "$PWN"
no_code "lazy fetch"

# A pager starts only on a terminal, as when a person tries the hook by hand.
if command -v script >/dev/null; then
  armed
  git config pager.add "$PWN"
  json="{\"tool_input\":{\"file_path\":\"$REPO/big.md\"}}"
  script -qec "echo '$json' | bash scripts/structure-hook" /dev/null </dev/null >/dev/null 2>&1
  if [ -e "$CANARY" ]; then bad "U1 pager on a terminal: repo's code ran"; else ok "U1 pager on a terminal: repo's code did not run"; fi
fi

# The issue's route: a clone holds a committed folder that passes for a bare repo.
armed
source=$REPO
clone="$WORK/clone$n"
mkdir -p evil/objects/x evil/refs/heads/x
touch evil/objects/x/keep evil/refs/heads/x/keep
echo 'ref: refs/heads/master' >evil/HEAD
mkfile evil/note.md 20004
printf '#!/bin/sh\necho ran >>"%s"\ncat\n' "$CANARY" >evil/pwn.sh
chmod 755 evil/pwn.sh
printf '[core]\n\trepositoryformatversion = 0\n\tworktree = ..\n\tfsmonitor = %s/evil/pwn.sh\n' "$clone" >evil/config
rm big.md
git add -A
git commit -qm evil
git clone -q "$source" "$clone"
REPO=$clone
no_code "bare-style folder in a clone" "$clone/evil/note.md" evil/note.md
cd "$WORK" || exit 1

# The hook writes nothing to the edited repo: no index, no objects.
fresh
mkfile big.md 20004
before="$(objects .)"
hook "$REPO/big.md"
flags big.md "U2 file in a repo with no index is checked"
if [ "$(objects .)" = "$before" ] && [ ! -e .git/index ]; then
  ok "U2 no objects and no index written to the repo"
else
  bad "U2 no objects and no index written to the repo"
fi

# What git read from the repo before still counts where it is data.
fresh
mkfile big.md 20004
mkdir -p .git/info
echo big.md >.git/info/exclude
hook "$REPO/big.md"
silent "U3 .git/info/exclude still ignores a file"

with_worktree
mkfile "$TREE/big.md" 20004
echo big.md >"$REPO/.git/info/exclude"
hook "$TREE/big.md"
silent "U3 a linked worktree reads the shared info/exclude"

fresh
mkfile big.md 20004
git add -A
git commit -qm big
hook "$REPO/big.md"
flags big.md "U4 a committed file git trusts by its stat data is sized"

fresh
rm -rf .git
git init -q --object-format=sha256
mkfile big.md 20004
hook "$REPO/big.md"
flags big.md "U4 a sha256 repo is checked"

fresh
git config core.splitIndex true
git add scripts
mkfile big.md 20004
hook "$REPO/big.md"
flags big.md "U4 a split-index repo is checked"

# Filters and fsmonitor of the user's own config are the user's: filters still
# apply, and fsmonitor stays off, since it would watch a folder about to go.
armed
printf '[core]\n\tfsmonitor = %s\n' "$PWN" >"$WORK/global$n"
GIT_CONFIG_GLOBAL="$WORK/global$n" hook "$REPO/big.md"
flags big.md "U5 global core.fsmonitor: file checked"
if [ -e "$CANARY" ]; then bad "U5 global core.fsmonitor stays off"; else ok "U5 global core.fsmonitor stays off"; fi
armed
echo 'big.md filter=shrink' >.gitattributes
printf '[filter "shrink"]\n\tclean = head -c 10\n' >"$WORK/global$n"
GIT_CONFIG_GLOBAL="$WORK/global$n" hook "$REPO/big.md"
silent "U5 a filter in the user's global config still applies"
