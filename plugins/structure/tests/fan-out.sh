# Tests for check-fan-out. Sourced by run.sh, which defines fresh, ok, bad
# and mkfile.

# Runs check-fan-out with the given arguments; sets RC and ERR.
fan() {
  ERR="$(bash scripts/check-fan-out "$@" 2>&1 >/dev/null)"
  RC=$?
}

# Writes $1 files, a1 to aN, in folder $2.
files() {
  local i
  for i in $(seq 1 "$1"); do mkfile "$2/a$i" 1; done
}

fanline() { printf 'fan-out: %s holds %s entries; the limit is 7' "$1" "$2"; }

# F1 eight entries fail, seven pass; the root never counts.
fresh
files 8 src
files 7 lib
files 9 .
git add -A
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline src 8)." <<<"$ERR" &&
  ! grep -qF ' lib ' <<<"$ERR" && ! grep -qF 'fan-out: . ' <<<"$ERR"; then
  ok "F1 over limit fails, at limit and root pass"
else
  bad "F1 over limit fails, at limit and root pass (rc=$RC)"
fi
if grep -qF 'Group by concept instead' <<<"$ERR" && grep -qF '.fan-out-excludes' <<<"$ERR"; then
  ok "F1 guidance names grouping and the excludes file"
else
  bad "F1 guidance names grouping and the excludes file"
fi
fan src/a1
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline src 8)." <<<"$ERR"; then
  ok "F1 a path checks its folder"
else
  bad "F1 a path checks its folder (rc=$RC)"
fi
fan lib/a1
if [ "$RC" -eq 0 ]; then ok "F1 a path in a small folder passes"; else bad "F1 a path in a small folder passes (rc=$RC)"; fi
fan "$REPO/src/a1"
if [ "$RC" -eq 1 ]; then ok "F1 an absolute path checks its folder"; else bad "F1 an absolute path checks its folder (rc=$RC)"; fi
fan /etc/hosts
if [ "$RC" -eq 0 ]; then ok "F1 a path outside the repo passes"; else bad "F1 a path outside the repo passes (rc=$RC)"; fi

# F2 folders above the path count too; dot folders never count.
fresh
for d in 1 2 3 4 5 6 7 8; do mkfile "top/d$d/x" 1; done
files 9 .github/workflows
git add -A
fan top/d1/x
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline top 8)." <<<"$ERR"; then
  ok "F2 a deep path checks every folder above it"
else
  bad "F2 a deep path checks every folder above it (rc=$RC)"
fi
fan .github/workflows/a1
if [ "$RC" -eq 0 ]; then ok "F2 dot folders are skipped"; else bad "F2 dot folders are skipped (rc=$RC)"; fi

# F3 a baseline absorbs today's count and fails on growth.
fresh
files 9 src
git add -A
printf '%s\n' '# accepted' 'src 9' >.fan-out-baseline
fan --all
if [ "$RC" -eq 0 ]; then ok "F3 baseline at count passes"; else bad "F3 baseline at count passes (rc=$RC)"; fi
mkfile src/a10 1
fan src/a10
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline src 10) and its baseline is 9." <<<"$ERR"; then
  ok "F3 growth past the baseline fails"
else
  bad "F3 growth past the baseline fails (rc=$RC)"
fi

# F4 an excluded folder passes; "*" stays in one folder, "**" crosses.
fresh
files 9 docs/log
files 9 a/b/c
files 9 x/y
git add -A
printf '%s\n' '# dated log' 'docs/log' '# generated' 'a/**' '# one level' '*' >.fan-out-excludes
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline x/y 9)." <<<"$ERR" &&
  ! grep -qF 'docs/log' <<<"$ERR" && ! grep -qF 'a/b/c' <<<"$ERR"; then
  ok "F4 excludes skip their folders, git glob rules"
else
  bad "F4 excludes skip their folders, git glob rules (rc=$RC)"
fi

# F5 untracked files count, ignored ones never do.
fresh
files 7 src
git add -A
mkfile src/new 1
fan src/new
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline src 8)." <<<"$ERR"; then
  ok "F5 an untracked file counts"
else
  bad "F5 an untracked file counts (rc=$RC)"
fi
echo 'src/new' >.gitignore
fan src/a1
if [ "$RC" -eq 0 ]; then ok "F5 an ignored file does not count"; else bad "F5 an ignored file does not count (rc=$RC)"; fi

# F6 --update-baseline lowers and drops, never raises or adds.
fresh
files 12 low
files 9 gone
files 10 grow
files 9 new
git add -A
printf '%s\n' '# kept comment' 'low 14' 'gone 9' 'grow 9' >.fan-out-baseline
git rm -rq --cached gone
rm -rf gone
mkfile grow/a11 1
fan --update-baseline
expected="$(printf '%s\n' '# kept comment' 'low 12' 'grow 9')"
if [ "$RC" -eq 0 ] && [ "$(cat .fan-out-baseline)" = "$expected" ]; then
  ok "F6 update lowers and drops, never raises or adds"
else
  bad "F6 update lowers and drops, never raises or adds (rc=$RC)"
fi
fan --all
if [ "$RC" -eq 1 ] && grep -qF 'fan-out: grow ' <<<"$ERR" && grep -qF 'fan-out: new ' <<<"$ERR"; then
  ok "F6 growth and new overages still fail after update"
else
  bad "F6 growth and new overages still fail after update (rc=$RC)"
fi

# F7 with no baseline file, --update-baseline writes today's overages.
fresh
files 9 src
files 8 b
git add -A
printf '%s\n' '# generated' 'b' >.fan-out-excludes
fan --update-baseline
if [ "$RC" -eq 0 ] && [ "$(grep -v '^#' .fan-out-baseline)" = "src 9" ]; then
  ok "F7 a missing baseline is written from today's overages"
else
  bad "F7 a missing baseline is written from today's overages (rc=$RC)"
fi

# F9 folders with a newline in their name count apart and keep their names: issue 337.
fresh
files 8 $'sub\n'
files 9 $'sub\n\n'
files 5 'lit\n'
files 5 $'lit\n'
git add -A
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline 'sub\n' 8)." <<<"$ERR" && grep -qxF "$(fanline 'sub\n\n' 9)." <<<"$ERR" &&
  [ "$(grep -c '^fan-out: ' <<<"$ERR")" -eq 2 ]; then
  ok "F9 two such folders report apart; a literal \\n in a name is another folder"
else
  bad "F9 two such folders report apart; a literal \\n in a name is another folder (rc=$RC: ${ERR:0:200})"
fi
fan $'sub\n/a1'
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline 'sub\n' 8)." <<<"$ERR" && ! grep -qF 'sub\n\n' <<<"$ERR"; then
  ok "F9 a path checks only its own such folder"
else
  bad "F9 a path checks only its own such folder (rc=$RC: ${ERR:0:200})"
fi

# F10 the name a report shows works in the baseline and the excludes.
printf '%s\n' 'sub\n 8' >.fan-out-baseline
fan $'sub\n/a1'
if [ "$RC" -eq 0 ]; then ok "F10 the shown name holds in the baseline"; else bad "F10 the shown name holds in the baseline (rc=$RC: ${ERR:0:200})"; fi
rm .fan-out-baseline
printf '%s\n' 'sub\n' >.fan-out-excludes
fan $'sub\n/a1'
if [ "$RC" -eq 0 ]; then ok "F10 the shown name holds in the excludes"; else bad "F10 the shown name holds in the excludes (rc=$RC: ${ERR:0:200})"; fi
rm .fan-out-excludes
fan --update-baseline
if [ "$RC" -eq 0 ] && [ "$(grep -v '^#' .fan-out-baseline | LC_ALL=C sort | tr '\n' ,)" = 'sub\n 8,sub\n\n 9,' ]; then
  ok "F10 --update-baseline writes the shown names"
else
  bad "F10 --update-baseline writes the shown names (rc=$RC)"
fi
fan --all
if [ "$RC" -eq 0 ]; then ok "F10 a written baseline holds"; else bad "F10 a written baseline holds (rc=$RC: ${ERR:0:200})"; fi
git rm -qf $'sub\n/a8'
fan --update-baseline
if [ "$RC" -eq 0 ] && grep -qxF 'sub\n\n 9' .fan-out-baseline && ! grep -qF 'sub\n ' .fan-out-baseline; then
  ok "F10 --update-baseline drops such a folder under the limit"
else
  bad "F10 --update-baseline drops such a folder under the limit (rc=$RC)"
fi

# F11 a backslash in a folder's name shows doubled; a folder named -n is checked.
fresh
files 8 'a\b'
files 8 -n
git add -A
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline 'a\\b' 8)." <<<"$ERR"; then ok "F11 a backslash shows doubled"; else bad "F11 a backslash shows doubled (rc=$RC: ${ERR:0:200})"; fi
fan 'a\b/a1'
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline 'a\\b' 8)." <<<"$ERR"; then ok "F11 a path into that folder checks it"; else bad "F11 a path into that folder checks it (rc=$RC: ${ERR:0:200})"; fi
printf '%s\n' 'a\\b' -n >.fan-out-excludes
fan --all
if [ "$RC" -eq 0 ]; then ok "F11 the shown name holds in the excludes"; else bad "F11 the shown name holds in the excludes (rc=$RC: ${ERR:0:200})"; fi
rm .fan-out-excludes
fan -n/a1
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline -n 8)." <<<"$ERR"; then ok "F11 a path into folder -n checks it"; else bad "F11 a path into folder -n checks it (rc=$RC: ${ERR:0:200})"; fi

# F8 no arguments is a usage error.
fan
if [ "$RC" -eq 2 ]; then ok "F8 no arguments exits 2"; else bad "F8 no arguments exits 2 (rc=$RC)"; fi
