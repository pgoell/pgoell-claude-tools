#!/usr/bin/env bash
# Tests the plugin's check-file-size and check-fan-out scripts, the fallback
# pre-commit hook and the Claude Code hook in throwaway git repos. No network.
# Run from the repo root: bash plugins/structure/tests/run.sh
set -uo pipefail

ASSETS="$(cd "$(dirname "$0")/../skills/setting-up-the-checks/assets" && pwd)"
SCRIPT="$ASSETS/check-file-size"
TESTS="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() {
  echo "ok   $1"
  pass=$((pass + 1))
}
bad() {
  echo "FAIL $1"
  fail=$((fail + 1))
}

# Writes a file of $2 bytes at path $1, creating its folders.
mkfile() {
  mkdir -p "$(dirname "$1")"
  head -c "$2" /dev/zero | tr '\0' a >"$1"
}

# Makes a fresh repo in $REPO with the scripts copied to scripts/, as the
# skill does in a target repo.
n=0
fresh() {
  n=$((n + 1))
  REPO="$WORK/repo$n"
  mkdir -p "$REPO/scripts"
  cp "$SCRIPT" "$REPO/scripts/check-file-size" 2>/dev/null
  cp "$ASSETS/check-fan-out" "$ASSETS/structure-hook" "$REPO/scripts/" 2>/dev/null
  cd "$REPO" || exit 1
  git init -q
  git config user.email test@example.com
  git config user.name test
}

# Runs the script with the given arguments; sets RC and ERR.
run() {
  ERR="$(bash scripts/check-file-size "$@" 2>&1 >/dev/null)"
  RC=$?
}

# Writes the repo's .file-size-excludes, one argument per line.
excludes() { printf '%s\n' "$@" >.file-size-excludes; }

passes() { [ "$RC" -eq 0 ] && [ -z "$ERR" ]; }
reports() { grep -qF "file-size: $1 " <<<"$ERR"; }

line() { printf 'file-size: %s is ~%s tokens (bytes/4); the limit is 5000.' "$1" "$2"; }

EXPECTED_GUIDANCE="$(printf '%s\n' \
  'Big files cost agents: they read them in pieces and lose track. Do not fix this' \
  'by cutting the file into parts by line count, or by moving code into' \
  'pass-through wrappers, barrel files or a utils grab bag. That gives many' \
  'shallow modules, and a reader then has to open all of them.' \
  '' \
  'Split along a deep module instead (John Ousterhout, "A Philosophy of Software' \
  'Design"): a module whose interface is small next to what it hides.' \
  '1. List what the file does. Find a group of functions that share state or' \
  '   knowledge the rest of the file does not need.' \
  '2. Move that group into its own module behind a few functions. Callers should' \
  '   not need to know how it works inside.' \
  '3. Check: if the new module'"'"'s interface is nearly as big as its body, or every' \
  '   caller still reaches into its details, you picked the wrong line. Try again.' \
  '- Tests: split by the behaviour or module under test, one file per unit,' \
  '  shared fixtures in one helper.' \
  '- Docs: split by topic into a folder with an index page that links them.' \
  '- Data (word lists, fixtures): move it into a data file and add it to the' \
  '  exclude list, if no person or agent edits it by hand.' \
  '- Skills: a SKILL.md over the limit moves step detail into references/ and' \
  '  links it from the step that needs it.')"

# A2/A5 over fails, A4 message.
fresh
mkfile big.md 20004
git add -A
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR"; then
  ok "A2/A5 over limit fails with the file line"
else
  bad "A2/A5 over limit fails with the file line (rc=$RC)"
fi
expected_all="$(line big.md 5001)"$'\n\n'"$EXPECTED_GUIDANCE"
if [ "$ERR" = "$expected_all" ]; then
  ok "A4 guidance text matches word for word"
else
  bad "A4 guidance text matches word for word"
fi

# A5 excluded passes: binaries, license texts and mise.lock by default, the
# rest through the repo's .file-size-excludes.
fresh
excludes '**/generated-*.mjs' 'plugins/diagrams/skills/creating-diagrams/engine/**' \
  'plugins/agent-system-management/skills/creating-skills/eval-viewer/viewer.html' \
  'plugins/deprecated/**'
excluded=(
  plugins/deprecated/x.md logo.png sub/dir/pic.png plugins/x/NOTICE
  plugins/x/LICENSE.txt mise.lock a/generated-y.mjs
  plugins/diagrams/skills/creating-diagrams/engine/z.mjs
  plugins/agent-system-management/skills/creating-skills/eval-viewer/viewer.html
)
for f in "${excluded[@]}"; do mkfile "$f" 20004; done
mkfile big.md 20004
git add -A
run
leaked=""
for f in "${excluded[@]}"; do reports "$f" && leaked="$leaked $f"; done
if [ "$RC" -eq 1 ] && [ -z "$leaked" ] && reports big.md; then
  ok "A5 excluded files not reported in full run"
else
  bad "A5 excluded files not reported in full run (rc=$RC leaked:$leaked)"
fi
run "${excluded[@]}"
if passes; then
  ok "A5 excluded files as arguments pass"
else
  bad "A5 excluded files as arguments pass (rc=$RC)"
fi
# One argument alone gives git a common prefix, which once hid the excludes.
leaked=""
for f in "${excluded[@]}"; do
  run "$f"
  passes || leaked="$leaked $f"
done
if [ -z "$leaked" ]; then
  ok "A5 each excluded file as a lone argument passes"
else
  bad "A5 each excluded file as a lone argument passes (leaked:$leaked)"
fi

# A3/I3 a repo glob in .file-size-excludes: absent from the defaults, so the
# file fails until the repo lists it, in a bare run and as an argument.
fresh
mkfile plugins/deprecated/x.md 20004
git add -A
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line plugins/deprecated/x.md 5001)" <<<"$ERR"; then
  ok "A3 plugins/deprecated/x.md fails a bare run on defaults alone"
else
  bad "A3 plugins/deprecated/x.md fails a bare run on defaults alone (rc=$RC)"
fi
run plugins/deprecated/x.md
if [ "$RC" -eq 1 ] && reports plugins/deprecated/x.md; then
  ok "A3 plugins/deprecated/x.md fails as an argument on defaults alone"
else
  bad "A3 plugins/deprecated/x.md fails as an argument on defaults alone (rc=$RC)"
fi
excludes 'plugins/deprecated/**'
run
if passes; then ok "I3 listed glob passes a bare run"; else bad "I3 listed glob passes a bare run (rc=$RC)"; fi
run plugins/deprecated/x.md
if passes; then ok "I3 listed glob passes as an argument"; else bad "I3 listed glob passes as an argument (rc=$RC)"; fi

# I2 comment lines and blank lines in .file-size-excludes are skipped.
fresh
printf '%s\n' '# generated output' '' '   ' 'skip/**' '  # big.md' '# big.md' >.file-size-excludes
mkfile skip/a.md 20004
mkfile big.md 20004
git add -A
run
if [ "$RC" -eq 1 ] && reports big.md && ! reports skip/a.md; then
  ok "I2 comments and blank lines ignored, glob line applies"
else
  bad "I2 comments and blank lines ignored, glob line applies (rc=$RC)"
fi

# A3/I2 a missing .file-size-excludes means the generic defaults only.
fresh
lockfiles=(package-lock.json web/package-lock.json sub/mise.lock yarn.lock
  pnpm-lock.yaml bun.lockb uv.lock poetry.lock Pipfile.lock Cargo.lock
  Gemfile.lock composer.lock go.sum flake.lock)
for f in "${lockfiles[@]}"; do mkfile "$f" 20004; done
git add -A
run
if passes; then
  ok "A3 big lockfiles pass with no excludes file"
else
  bad "A3 big lockfiles pass with no excludes file (rc=$RC)"
fi
mkfile x.md 20004
git add -A
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line x.md 5001)" <<<"$ERR" && ! reports package-lock.json; then
  ok "A3 big x.md fails with no excludes file"
else
  bad "A3 big x.md fails with no excludes file (rc=$RC)"
fi

# I2 a run from a subdirectory reads the excludes file at the repo root.
fresh
excludes 'sub/gen/**'
mkfile sub/gen/x.md 20004
mkfile sub/deep.md 20004
git add -A
cd sub || exit 1
ERR="$(bash ../scripts/check-file-size 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && reports sub/deep.md && ! reports sub/gen/x.md; then
  ok "I2 bare run from a subdirectory keeps the root excludes"
else
  bad "I2 bare run from a subdirectory keeps the root excludes (rc=$RC)"
fi
ERR="$(bash ../scripts/check-file-size gen/x.md 2>&1 >/dev/null)"
RC=$?
if passes; then
  ok "I2 excluded argument from a subdirectory passes"
else
  bad "I2 excluded argument from a subdirectory passes (rc=$RC)"
fi

# A5/I1 under passes, boundary.
fresh
mkfile small.md 20000
mkfile edge.md 20003
git add -A
run
if passes; then
  ok "A5/I1 20000 and 20003 bytes pass, clean run is silent"
else
  bad "A5/I1 20000 and 20003 bytes pass, clean run is silent (rc=$RC)"
fi

# I1 the staged copy is sized, not the worktree.
fresh
mkfile big.md 20004
git add -A
mkfile big.md 100
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR"; then
  ok "I1 staged big, worktree small fails"
else
  bad "I1 staged big, worktree small fails (rc=$RC)"
fi
fresh
mkfile small.md 100
git add -A
mkfile small.md 20004
run
if passes; then
  ok "I1 staged small, worktree big passes"
else
  bad "I1 staged small, worktree big passes (rc=$RC)"
fi

# I1 a bare run (pre-push) sizes HEAD, not the index.
fresh
mkfile big.md 20004
git add -A
git commit -qm init
mkfile big.md 100
git add -A
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR"; then
  ok "I1 bare run sizes HEAD: committed big, staged small fails"
else
  bad "I1 bare run sizes HEAD: committed big, staged small fails (rc=$RC)"
fi
fresh
mkfile small.md 100
git add -A
git commit -qm init
mkfile small.md 20004
git add -A
run
if passes; then
  ok "I1 bare run sizes HEAD: committed small, staged big passes"
else
  bad "I1 bare run sizes HEAD: committed small, staged big passes (rc=$RC)"
fi

# I2 arguments match literally, not as globs.
fresh
mkfile abig.md 20004
mkfile 'a*.md' 100
git add -A
run 'a*.md'
if passes; then
  ok "I2 literal: argument 'a*.md' does not match abig.md"
else
  bad "I2 literal: argument 'a*.md' does not match abig.md (rc=$RC)"
fi

# I2 arguments limit the check; a path removed from the worktree is still sized.
fresh
mkfile small.md 20000
mkfile big.md 20004
mkfile gone.md 30000
git add -A
rm gone.md
run small.md
if passes; then ok "I2 small.md argument passes"; else bad "I2 small.md argument passes (rc=$RC)"; fi
run big.md
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR"; then ok "I2 big.md argument fails"; else bad "I2 big.md argument fails (rc=$RC)"; fi
run gone.md
if [ "$RC" -eq 1 ] && grep -qxF "$(line gone.md 7500)" <<<"$ERR"; then
  ok "I2 staged path removed from the worktree fails"
else
  bad "I2 staged path removed from the worktree fails (rc=$RC)"
fi

# I3 two failures, guidance once.
fresh
mkfile big.md 20004
mkfile big2.md 20008
git add -A
run
count="$(grep -cF 'Big files cost agents' <<<"$ERR")"
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR" &&
  grep -qxF "$(line big2.md 5002)" <<<"$ERR" && [ "$count" -eq 1 ]; then
  ok "I3 both files reported, guidance once"
else
  bad "I3 both files reported, guidance once (rc=$RC count=$count)"
fi

# I4 path with a space.
fresh
mkfile "has space.md" 20004
git add -A
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line "has space.md" 5001)" <<<"$ERR"; then
  ok "I4 path with a space reported in full"
else
  bad "I4 path with a space reported in full (rc=$RC)"
fi

# I5 tracked symlink not reported.
fresh
mkfile big.md 20004
ln -s big.md link.md
git add -A
run
if [ "$RC" -eq 1 ] && ! grep -qF "link.md" <<<"$ERR" && reports big.md; then
  ok "I5 symlink not reported"
else
  bad "I5 symlink not reported (rc=$RC)"
fi

# A2 token count.
fresh
mkfile forty.md 40000
git add -A
run
if [ "$RC" -eq 1 ] && grep -qxF "$(line forty.md 10000)" <<<"$ERR"; then
  ok "A2 40000 bytes is 10000 tokens"
else
  bad "A2 40000 bytes is 10000 tokens (rc=$RC)"
fi

# B1 a failing git ls-files fails the check.
fresh
mkfile small.md 100
git add -A
run /etc/passwd
if [ "$RC" -ne 0 ]; then ok "B1 path outside the repo fails"; else bad "B1 path outside the repo fails (rc=$RC)"; fi
NOGIT="$WORK/nogit"
mkdir -p "$NOGIT"
cd "$NOGIT" || exit 1
ERR="$(GIT_CEILING_DIRECTORIES="$WORK" bash "$REPO/scripts/check-file-size" 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -ne 0 ]; then ok "B1 run outside a git repo fails"; else bad "B1 run outside a git repo fails (rc=$RC)"; fi

# B2 paths given from a subdirectory resolve against it.
fresh
mkfile big.md 20004
mkfile sub/deep.md 20004
mkfile sub/pic.png 20004
git add -A
cd sub || exit 1
ERR="$(bash ../scripts/check-file-size deep.md 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -qxF "$(line sub/deep.md 5001)" <<<"$ERR"; then
  ok "B2 relative argument from a subdirectory fails"
else
  bad "B2 relative argument from a subdirectory fails (rc=$RC)"
fi
ERR="$(bash ../scripts/check-file-size 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR" &&
  grep -qxF "$(line sub/deep.md 5001)" <<<"$ERR" && ! grep -qF "pic.png" <<<"$ERR"; then
  ok "B2 no-arg run from a subdirectory checks the whole repo, keeps excludes"
else
  bad "B2 no-arg run from a subdirectory checks the whole repo, keeps excludes (rc=$RC)"
fi
ERR="$(bash ../scripts/check-file-size pic.png 2>&1 >/dev/null)"
RC=$?
if passes; then
  ok "B2 excluded argument from a subdirectory passes"
else
  bad "B2 excluded argument from a subdirectory passes (rc=$RC)"
fi

# A7/I5 the fallback pre-commit hook blocks an over-limit staged file without
# lefthook. The big file sits under plugins/deprecated/, which only a repo's
# own excludes may skip, and its name has a space to test the -z pipe.
fresh
mkdir -p .githooks
cp "$ASSETS/pre-commit" .githooks/pre-commit
git config core.hooksPath .githooks
mkfile "plugins/deprecated/big file.md" 20004
git add -A
ERR="$(git commit -qm big 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -ne 0 ] && ! git rev-parse -q --verify HEAD >/dev/null &&
  grep -qxF "$(line "plugins/deprecated/big file.md" 5001)" <<<"$ERR"; then
  ok "A7 pre-commit hook blocks an over-limit file"
else
  bad "A7 pre-commit hook blocks an over-limit file (rc=$RC)"
fi
git rm -q --cached "plugins/deprecated/big file.md"
mkfile "small file.md" 100
git add "small file.md"
ERR="$(git commit -qm small 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 0 ] && git rev-parse -q --verify HEAD >/dev/null; then
  ok "A7 pre-commit hook lets a small file through"
else
  bad "A7 pre-commit hook lets a small file through (rc=$RC)"
fi

# shellcheck source=fan-out.sh
. "$TESTS/fan-out.sh"
# shellcheck source=hook.sh
. "$TESTS/hook.sh"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
