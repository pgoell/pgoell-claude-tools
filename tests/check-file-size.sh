#!/usr/bin/env bash
# Tests mise-tasks/check-file-size in throwaway git repos. No network.
# Run from the repo root: bash tests/check-file-size.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/mise-tasks/check-file-size"
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

# Makes a fresh repo in $REPO with the script copied in.
n=0
fresh() {
  n=$((n + 1))
  REPO="$WORK/repo$n"
  mkdir -p "$REPO/mise-tasks"
  cp "$SCRIPT" "$REPO/mise-tasks/check-file-size" 2>/dev/null
  cd "$REPO" || exit 1
  git init -q
  git config user.email test@example.com
  git config user.name test
}

# Runs the script with the given arguments; sets RC and ERR.
run() {
  ERR="$(bash mise-tasks/check-file-size "$@" 2>&1 >/dev/null)"
  RC=$?
}

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

# A5 excluded passes.
fresh
excluded=(
  plugins/deprecated/x.md logo.png sub/dir/pic.png plugins/x/NOTICE
  plugins/x/LICENSE.txt mise.lock a/generated-y.mjs
  plugins/diagrams/skills/creating-diagrams/engine/z.mjs
  plugins/workbench/skills/crafting-html/references/01-a.html
  plugins/agent-system-management/skills/creating-skills/eval-viewer/viewer.html
)
for f in "${excluded[@]}"; do mkfile "$f" 20004; done
mkfile big.md 20004
git add -A
run
leaked=""
for f in "${excluded[@]}"; do
  grep -qF "file-size: $f " <<<"$ERR" && leaked="$leaked $f"
done
if [ "$RC" -eq 1 ] && [ -z "$leaked" ] && grep -qF "file-size: big.md " <<<"$ERR"; then
  ok "A5 excluded files not reported in full run"
else
  bad "A5 excluded files not reported in full run (rc=$RC leaked:$leaked)"
fi
run "${excluded[@]}"
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then
  ok "A5 excluded files as arguments pass"
else
  bad "A5 excluded files as arguments pass (rc=$RC)"
fi
# One argument alone gives git a common prefix, which once hid the excludes.
leaked=""
for f in "${excluded[@]}"; do
  run "$f"
  [ "$RC" -eq 0 ] && [ -z "$ERR" ] || leaked="$leaked $f"
done
if [ -z "$leaked" ]; then
  ok "A5 each excluded file as a lone argument passes"
else
  bad "A5 each excluded file as a lone argument passes (leaked:$leaked)"
fi

# A5 under passes, I1 boundary.
fresh
mkfile small.md 20000
mkfile edge.md 20003
git add -A
run
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then
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
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then
  ok "I1 staged small, worktree big passes"
else
  bad "I1 staged small, worktree big passes (rc=$RC)"
fi

# I2 arguments match literally, not as globs.
fresh
mkfile abig.md 20004
mkfile 'a*.md' 100
git add -A
run 'a*.md'
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then
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
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then ok "I2 small.md argument passes"; else bad "I2 small.md argument passes (rc=$RC)"; fi
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
if [ "$RC" -eq 1 ] && ! grep -qF "link.md" <<<"$ERR" && grep -qF "file-size: big.md " <<<"$ERR"; then
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
ERR="$(GIT_CEILING_DIRECTORIES="$WORK" bash "$REPO/mise-tasks/check-file-size" 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -ne 0 ]; then ok "B1 run outside a git repo fails"; else bad "B1 run outside a git repo fails (rc=$RC)"; fi

# B2 paths given from a subdirectory resolve against it.
fresh
mkfile big.md 20004
mkfile sub/deep.md 20004
mkfile sub/pic.png 20004
git add -A
cd sub || exit 1
ERR="$(bash ../mise-tasks/check-file-size deep.md 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -qxF "$(line sub/deep.md 5001)" <<<"$ERR"; then
  ok "B2 relative argument from a subdirectory fails"
else
  bad "B2 relative argument from a subdirectory fails (rc=$RC)"
fi
ERR="$(bash ../mise-tasks/check-file-size 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 1 ] && grep -qxF "$(line big.md 5001)" <<<"$ERR" &&
  grep -qxF "$(line sub/deep.md 5001)" <<<"$ERR" && ! grep -qF "pic.png" <<<"$ERR"; then
  ok "B2 no-arg run from a subdirectory checks the whole repo, keeps excludes"
else
  bad "B2 no-arg run from a subdirectory checks the whole repo, keeps excludes (rc=$RC)"
fi
ERR="$(bash ../mise-tasks/check-file-size pic.png 2>&1 >/dev/null)"
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$ERR" ]; then
  ok "B2 excluded argument from a subdirectory passes"
else
  bad "B2 excluded argument from a subdirectory passes (rc=$RC)"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
