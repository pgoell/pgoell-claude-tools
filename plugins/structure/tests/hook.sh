# Tests for structure-hook with fake PostToolUse JSON. Sourced by run.sh,
# which defines fresh, ok, bad and mkfile.

# Feeds a hook (scripts/structure-hook, or path $2) a Write event for path $1;
# sets RC and ERR.
hook() {
  ERR="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":""}}' "$1" |
    timeout 20 bash "${2:-scripts/structure-hook}" 2>&1 >/dev/null)"
  RC=$?
}

# H1 a big untracked file reaches Claude with exit 2; the index is untouched.
fresh
mkfile small.md 100
git add -A
before="$(git ls-files -s)"
mkfile "$REPO/big.md" 20004
hook "$REPO/big.md"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: big.md is ~5001 tokens' <<<"$ERR" &&
  [ "$(git ls-files -s)" = "$before" ]; then
  ok "H1 big new file exits 2, real index unchanged"
else
  bad "H1 big new file exits 2, real index unchanged (rc=$RC)"
fi

# H2 the size on disk counts, not the staged copy.
fresh
mkfile doc.md 100
git add -A
git commit -qm init
mkfile doc.md 20004
hook "$REPO/doc.md"
if [ "$RC" -eq 2 ]; then ok "H2 tracked file grown on disk exits 2"; else bad "H2 tracked file grown on disk exits 2 (rc=$RC)"; fi

# H3 a crowded folder reaches Claude; a small one passes silently.
fresh
for i in 1 2 3 4 5 6 7 8; do mkfile "src/m$i.py" 1; done
hook "$REPO/src/m8.py"
if [ "$RC" -eq 2 ] && grep -qF 'fan-out: src holds 8 entries' <<<"$ERR"; then
  ok "H3 crowded folder exits 2"
else
  bad "H3 crowded folder exits 2 (rc=$RC)"
fi
mkfile "$REPO/lib/ok.py" 1
hook "$REPO/lib/ok.py"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "H3 small file in a small folder passes"; else bad "H3 small file in a small folder passes (rc=$RC)"; fi

# H4 files outside a repo, ignored files and missing paths pass.
mkdir -p "$WORK/outside"
mkfile "$WORK/outside/big.md" 20004
GIT_CEILING_DIRECTORIES="$WORK" hook "$WORK/outside/big.md"
rc_out=$RC
echo 'big-ignored.md' >.gitignore
mkfile big-ignored.md 20004
hook "$REPO/big-ignored.md"
rc_ign=$RC
hook "$REPO/nope.md"
if [ "$rc_out" -eq 0 ] && [ "$rc_ign" -eq 0 ] && [ "$RC" -eq 0 ]; then
  ok "H4 outside, ignored and missing files pass"
else
  bad "H4 outside, ignored and missing files pass (rc=$rc_out/$rc_ign/$RC)"
fi

# Counts the objects in the repo at $1.
objects() { find "$1/.git/objects" -type f | wc -l; }

# Replaces the hook at $1 with a stub that names itself: it must never run.
stub() {
  printf '#!/usr/bin/env bash\necho "stub %s" >&2\nexit 2\n' "$1" >"$1"
  chmod 755 "$1"
}

# H5 issue 294: an ignored nested repo without the hook is not judged or written
# to, here with 10 files in one folder and a big one.
fresh
echo '/vault/' >.gitignore
git init -q vault
for i in 1 2 3 4 5 6 7 8 9 10; do mkfile "vault/notes/n$i.md" 1; done
mkfile vault/notes/big.md 20004
before="$(objects vault)"
hook "$REPO/vault/notes/n1.md"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "H5 file in an ignored nested repo passes in silence"; else bad "H5 file in an ignored nested repo passes in silence (rc=$RC: $ERR)"; fi
hook "$REPO/vault/notes/big.md"
if [ "$(objects vault)" = "$before" ] && [ ! -e vault/.git/index ]; then
  ok "H5 no loose objects and no index in the nested repo"
else
  bad "H5 no loose objects and no index in the nested repo ($before, now $(objects vault))"
fi

# H6 the hook finds its own repo wherever it sits: a kasten-style folder, a
# deep plugin folder, the repo root. A subfolder file is checked in each.
for at in scripts/structure plugins/x/assets .; do
  fresh
  mkdir -p "$at"
  mv scripts/check-file-size scripts/check-fan-out scripts/structure-hook "$at/"
  mkfile "$REPO/sub/big.md" 20004
  hook "$REPO/sub/big.md" "$at/structure-hook"
  if [ "$RC" -eq 2 ] && grep -qF 'file-size: sub/big.md is ~5001 tokens' <<<"$ERR"; then
    ok "H6 hook in $at checks a file of its repo"
  else
    bad "H6 hook in $at checks a file of its repo (rc=$RC: $ERR)"
  fi
done

# Makes a repo with the hook committed and a linked worktree in $TREE.
with_worktree() {
  fresh
  git add -A
  git commit -qm init
  TREE="$WORK/tree$n"
  git worktree add -q -b "wt$n" "$TREE"
}

# H7 a hook in a linked worktree checks a file of that worktree.
with_worktree
mkfile "$TREE/big.md" 20004
hook "$TREE/big.md" "$TREE/scripts/structure-hook"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: big.md is ~5001 tokens' <<<"$ERR" && [ "$(git -C "$TREE" ls-files -s big.md)" = "" ]; then
  ok "H7 hook in a linked worktree checks its file, index unchanged"
else
  bad "H7 hook in a linked worktree checks its file, index unchanged (rc=$RC: $ERR)"
fi

# H8 a file in another checkout meets that checkout's baseline, both ways, and
# that checkout's copy of the hook does not run.
with_worktree
for i in 1 2 3 4 5 6 7 8; do
  mkfile "$TREE/src/m$i.py" 1
  mkfile "$REPO/src/m$i.py" 1
done
echo 'src 8' >"$TREE/.fan-out-baseline"
stub "$TREE/scripts/structure-hook"
hook "$TREE/src/m1.py"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "H8 main's hook keeps to the worktree's baseline"; else bad "H8 main's hook keeps to the worktree's baseline (rc=$RC: $ERR)"; fi
git -C "$TREE" checkout -q -- scripts/structure-hook
stub "$REPO/scripts/structure-hook"
hook "$REPO/src/m1.py" "$TREE/scripts/structure-hook"
if [ "$RC" -eq 2 ] && grep -qF 'fan-out: src holds 8 entries' <<<"$ERR" && ! grep -qF stub <<<"$ERR"; then
  ok "H8 the worktree's hook keeps to main, which has no baseline"
else
  bad "H8 the worktree's hook keeps to main, which has no baseline (rc=$RC: $ERR)"
fi

# H9 a nested repo that set up the checks is checked with its own excludes, and
# its copy of the hook does not run: the edited repo may be one nobody has read.
fresh
outer=$REPO
echo '/inner/' >.gitignore
mkdir -p inner/scripts
git init -q inner
stub "$outer/inner/scripts/structure-hook"
mkfile inner/big.md 20004
mkfile inner/gen.md 20004
echo 'gen.md' >inner/.file-size-excludes
hook "$outer/inner/big.md"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: big.md is ~5001 tokens' <<<"$ERR" && ! grep -qF stub <<<"$ERR"; then
  ok "H9 nested repo with the hook is checked, its copy not run"
else
  bad "H9 nested repo with the hook is checked, its copy not run (rc=$RC: $ERR)"
fi
hook "$outer/inner/gen.md"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "H9 nested repo's excludes apply"; else bad "H9 nested repo's excludes apply (rc=$RC: $ERR)"; fi

# H10 a worktree of a branch without the hook passes in silence.
with_worktree
git -C "$TREE" rm -qr scripts
git -C "$TREE" commit -qm 'no hook'
mkfile "$TREE/big.md" 20004
hook "$TREE/big.md"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "H10 worktree without the hook passes"; else bad "H10 worktree without the hook passes (rc=$RC: $ERR)"; fi

# H11 spaces in the path, a checkout reached through a symlink, and a scripts
# folder that links into another repo run in place, with no exec loop.
n=$((n + 1))
REPO="$WORK/has space $n"
mkdir -p "$REPO/scripts"
cp "$ASSETS/check-file-size" "$ASSETS/check-fan-out" "$ASSETS/structure-hook" "$REPO/scripts/"
cd "$REPO" || exit 1
git init -q
mkfile "$REPO/big.md" 20004
hook "$REPO/big.md"
if [ "$RC" -eq 2 ]; then ok "H11 path with a space is checked"; else bad "H11 path with a space is checked (rc=$RC: $ERR)"; fi
ln -s "$REPO" "$WORK/link$n"
hook "$REPO/big.md" "$WORK/link$n/scripts/structure-hook"
if [ "$RC" -eq 2 ]; then ok "H11 hook through a symlinked checkout, file by real path"; else bad "H11 hook through a symlinked checkout, file by real path (rc=$RC: $ERR)"; fi
hook "$WORK/link$n/big.md"
if [ "$RC" -eq 2 ]; then ok "H11 file through a symlinked checkout"; else bad "H11 file through a symlinked checkout (rc=$RC: $ERR)"; fi
shared=$REPO
fresh
rm -rf scripts
ln -s "$shared/scripts" scripts
mkfile "$REPO/big.md" 20004
hook "$REPO/big.md"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: big.md is ~5001 tokens' <<<"$ERR"; then
  ok "H11 scripts folder linked from another repo runs in place"
else
  bad "H11 scripts folder linked from another repo runs in place (rc=$RC: $ERR)"
fi

# H12 a relative file_path still reaches a file in the other checkout.
with_worktree
mkfile "$TREE/sub/big.md" 20004
cd "$TREE/sub" || exit 1
hook big.md "$REPO/scripts/structure-hook"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: sub/big.md is ~5001 tokens' <<<"$ERR"; then
  ok "H12 relative path reaches the other checkout"
else
  bad "H12 relative path reaches the other checkout (rc=$RC: $ERR)"
fi

# Expects exit 2 with file-size line $1 for test name $2, and no stub's words.
flags() {
  if [ "$RC" -eq 2 ] && grep -qF "file-size: $1 is ~5001 tokens" <<<"$ERR" && ! grep -qF stub <<<"$ERR"; then
    ok "$2"
  else
    bad "$2 (rc=$RC: $ERR)"
  fi
}

# Expects exit 0 and no words for test name $1.
silent() {
  if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "$1"; else bad "$1 (rc=$RC: $ERR)"; fi
}

# Moves this repo's scripts to folder $1 and leaves a scripts symlink to it.
link_scripts() {
  mkdir -p "$1"
  mv scripts/* "$1/"
  rmdir scripts
  ln -s "$1" scripts
}

# H13 issue 321, a regression from PR 319: scripts/ is a symlink, and git asked
# in the folder it reaches names no path in this repo.
fresh
link_scripts "$WORK/shared$n"
mkfile src/big.md 20004
hook "$REPO/src/big.md" "$REPO/scripts/structure-hook"
flags src/big.md "H13 scripts linked to a folder outside any repo is checked"
fresh
mkfile src/big.md 20004
ln -s "$REPO/scripts" "$WORK/tools$n"
hook "$REPO/src/big.md" "$WORK/tools$n/structure-hook"
flags src/big.md "H13 hook called through a link from outside any repo is checked"

other="$WORK/other$n"
git init -q "$other"
fresh
link_scripts "$other/deep/tools"
mkfile src/big.md 20004
hook "$REPO/src/big.md" "$REPO/scripts/structure-hook"
flags src/big.md "H13 scripts linked to a subfolder of another repo is checked"

# The link does not widen the check: a nested repo with no copy stays silent, and
# one with a copy has it stay unrun.
echo '/inner/' >.gitignore
git init -q inner
mkfile inner/big.md 20004
before="$(objects inner)"
hook "$REPO/inner/big.md" "$REPO/scripts/structure-hook"
silent "H13 linked scripts, nested repo with no copy passes in silence"
if [ "$(objects inner)" = "$before" ] && [ ! -e inner/.git/index ]; then
  ok "H13 linked scripts, nothing written to the nested repo"
else
  bad "H13 linked scripts, nothing written to the nested repo"
fi
mkdir inner/scripts
stub "$REPO/inner/scripts/structure-hook"
hook "$REPO/inner/big.md" "$REPO/scripts/structure-hook"
flags big.md "H13 linked scripts, nested repo's copy is found and not run"

# H14 issue 321, a regression from PR 319: GIT_DIR alone makes git take the
# current folder as the top of the work tree.
fresh
mkfile src/small.md 100
git add -A
before="$(git ls-files -s)"
mkfile src/big.md 20004
GIT_DIR="$REPO/.git" hook "$REPO/src/big.md"
flags src/big.md "H14 GIT_DIR without GIT_WORK_TREE is checked"
GIT_DIR=.git GIT_INDEX_FILE=.git/index hook "$REPO/src/big.md"
flags src/big.md "H14 relative GIT_DIR and GIT_INDEX_FILE, as from a git hook, is checked"
if [ "$(git ls-files -s)" = "$before" ]; then ok "H14 real index unchanged"; else bad "H14 real index unchanged"; fi

# The file's own repo decides, not the caller's: a nested repo with no copy stays
# silent under GIT_DIR, and a pair at repo A does not steer a file in repo B.
echo '/inner/' >.gitignore
git init -q inner
mkfile inner/big.md 20004
before="$(objects inner)"
outer="$(objects .)"
GIT_DIR="$REPO/.git" hook "$REPO/inner/big.md"
silent "H14 GIT_DIR, nested repo with no copy passes in silence"
if [ "$(objects inner)" = "$before" ] && [ "$(objects .)" = "$outer" ]; then
  ok "H14 GIT_DIR, nothing written to either repo"
else
  bad "H14 GIT_DIR, nothing written to either repo"
fi
a=$REPO
fresh
mkfile "$REPO/src/big.md" 20004
outer="$(objects "$a")"
GIT_DIR="$a/.git" GIT_WORK_TREE="$a" hook "$REPO/src/big.md"
flags src/big.md "H14 GIT_DIR and GIT_WORK_TREE at another repo, the file's repo is checked"
if [ "$(objects "$a")" = "$outer" ]; then ok "H14 nothing written to the other repo"; else bad "H14 nothing written to the other repo"; fi
