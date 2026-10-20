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

# F8 no arguments is a usage error.
fan
if [ "$RC" -eq 2 ]; then ok "F8 no arguments exits 2"; else bad "F8 no arguments exits 2 (rc=$RC)"; fi
