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

# Replaces the hook at $1 with a stub that names itself, to show which copy ran.
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

# H8 a file in another checkout of the repo goes to that checkout's copy, both ways.
with_worktree
mkfile "$TREE/x.md" 1
mkfile "$REPO/y.md" 1
stub "$TREE/scripts/structure-hook"
hook "$TREE/x.md"
if [ "$RC" -eq 2 ] && [ "$ERR" = "stub $TREE/scripts/structure-hook" ]; then ok "H8 main's hook calls the worktree's copy"; else bad "H8 main's hook calls the worktree's copy (rc=$RC: $ERR)"; fi
git -C "$REPO" checkout -q -- scripts/structure-hook
git -C "$TREE" checkout -q -- scripts/structure-hook
stub "$REPO/scripts/structure-hook"
hook "$REPO/y.md" "$TREE/scripts/structure-hook"
if [ "$RC" -eq 2 ] && [ "$ERR" = "stub $REPO/scripts/structure-hook" ]; then ok "H8 the worktree's hook calls main's copy"; else bad "H8 the worktree's hook calls main's copy (rc=$RC: $ERR)"; fi

# H9 a nested repo that set up the checks itself is checked by its own copy.
fresh
outer=$REPO
echo '/inner/' >.gitignore
mkdir -p inner/scripts
git init -q inner
stub "$outer/inner/scripts/structure-hook"
mkfile inner/x.md 1
hook "$outer/inner/x.md"
if [ "$RC" -eq 2 ] && [ "$ERR" = "stub $outer/inner/scripts/structure-hook" ]; then ok "H9 nested repo with the hook runs its own copy"; else bad "H9 nested repo with the hook runs its own copy (rc=$RC: $ERR)"; fi

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

# H12 a relative file_path still reaches the file through the other copy.
with_worktree
mkfile "$TREE/sub/big.md" 20004
cd "$TREE/sub" || exit 1
hook big.md "$REPO/scripts/structure-hook"
if [ "$RC" -eq 2 ] && grep -qF 'file-size: sub/big.md is ~5001 tokens' <<<"$ERR"; then
  ok "H12 relative path goes through the other copy"
else
  bad "H12 relative path goes through the other copy (rc=$RC: $ERR)"
fi
