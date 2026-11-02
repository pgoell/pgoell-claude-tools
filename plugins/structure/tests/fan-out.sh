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

# Writes the lines given to .fan-out-excludes.
fan_excludes() { printf '%s\n' "$@" >.fan-out-excludes; }

# F12 an exclude takes "[" and "^" as plain characters: issue 339, part 1.
fresh
files 8 'a[b'
git add -A
fan_excludes 'a[b'
fan --all
if [ "$RC" -eq 0 ]; then ok "F12 an exclude with [ matches its folder"; else bad "F12 an exclude with [ matches its folder (rc=$RC: ${ERR:0:200})"; fi
fresh
files 8 'c^d'
git add -A
fan_excludes 'c^d'
fan --all
if [ "$RC" -eq 0 ]; then ok "F12 an exclude with ^ matches its folder"; else bad "F12 an exclude with ^ matches its folder (rc=$RC: ${ERR:0:200})"; fi
fresh
for d in 'a[b]' ab x q1 q/r; do files 8 "$d"; done
git add -A
fan_excludes 'a[b]' '%%A%%x' 'q?'
fan --all
if [ "$RC" -eq 1 ] && ! grep -qF 'fan-out: a[b] ' <<<"$ERR" && ! grep -qF 'fan-out: q1 ' <<<"$ERR" &&
  grep -qF 'fan-out: ab ' <<<"$ERR" && grep -qF 'fan-out: x ' <<<"$ERR" && grep -qF 'fan-out: q/r ' <<<"$ERR"; then
  ok "F12 a[b] is no class, %%A%% is plain, ? stays in one folder"
else
  bad "F12 a[b] is no class, %%A%% is plain, ? stays in one folder (rc=$RC: ${ERR:0:300})"
fi

# F13 --update-baseline writes lines it can read: issue 339, part 2.
fresh
files 8 '#x'
files 8 ' y'
files 8 'a /b'
git add -A
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline '\#x' 8)." <<<"$ERR" && grep -qxF "$(fanline '\sy' 8)." <<<"$ERR"; then
  ok "F13 a report writes # and a space that start a name as \\# and \\s"
else
  bad "F13 a report writes # and a space that start a name as \\# and \\s (rc=$RC: ${ERR:0:200})"
fi
fan --update-baseline
fan --all
if [ "$RC" -eq 0 ]; then ok "F13 a written baseline holds for # and a leading space"; else bad "F13 a written baseline holds for # and a leading space (rc=$RC: ${ERR:0:200})"; fi
mkfile '#x/a9' 1
mkfile ' y/a9' 1
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline '\#x' 9) and its baseline is 8." <<<"$ERR" &&
  grep -qxF "$(fanline '\sy' 9) and its baseline is 8." <<<"$ERR"; then
  ok "F13 growth past such a line fails"
else
  bad "F13 growth past such a line fails (rc=$RC: ${ERR:0:200})"
fi
fan '#x/a9'
if [ "$RC" -eq 1 ] && [ "$(grep -c '^fan-out: ' <<<"$ERR")" -eq 1 ]; then ok "F13 a path into #x checks it"; else bad "F13 a path into #x checks it (rc=$RC: ${ERR:0:200})"; fi
fan ' y/a9'
if [ "$RC" -eq 1 ] && [ "$(grep -c '^fan-out: ' <<<"$ERR")" -eq 1 ]; then ok "F13 a path into a leading-space folder checks it"; else bad "F13 a path into a leading-space folder checks it (rc=$RC: ${ERR:0:200})"; fi
printf '%s\n' '# kept' '\#x 12' '\sy 9' 'a /b 8' >.fan-out-baseline
rm ' y/a9' ' y/a8'
git add -A
fan --update-baseline
if [ "$RC" -eq 0 ] && [ "$(cat .fan-out-baseline)" = "$(printf '%s\n' '# kept' '\#x 9' 'a /b 8')" ]; then
  ok "F13 update lowers and drops such lines"
else
  bad "F13 update lowers and drops such lines (rc=$RC: $(cat .fan-out-baseline))"
fi
rm .fan-out-baseline
fan_excludes '\#x' 'a /b'
fan --all
if [ "$RC" -eq 0 ]; then ok "F13 the shown name holds in the excludes"; else bad "F13 the shown name holds in the excludes (rc=$RC: ${ERR:0:200})"; fi
fresh
files 8 ' y'
git add -A
fan_excludes '\sy'
fan --all
if [ "$RC" -eq 0 ]; then ok "F13 \\s holds in the excludes"; else bad "F13 \\s holds in the excludes (rc=$RC: ${ERR:0:200})"; fi

# F14 a tab or a carriage return in a name, which trimming would eat.
fresh
files 8 $'t\tb'
files 8 $'\tc'
files 8 $'d\r'
git add -A
fan --all
if [ "$RC" -eq 1 ] && grep -qxF "$(fanline 't\tb' 8)." <<<"$ERR" && grep -qxF "$(fanline '\tc' 8)." <<<"$ERR" &&
  grep -qxF "$(fanline 'd\r' 8)." <<<"$ERR"; then
  ok "F14 a report writes a tab as \\t and a CR as \\r"
else
  bad "F14 a report writes a tab as \\t and a CR as \\r (rc=$RC: ${ERR:0:200})"
fi
fan --update-baseline
fan --all
if [ "$RC" -eq 0 ]; then ok "F14 a written baseline holds"; else bad "F14 a written baseline holds (rc=$RC: ${ERR:0:200})"; fi
rm .fan-out-baseline
fan_excludes 't\tb' '\tc' 'd\r'
fan --all
if [ "$RC" -eq 0 ]; then ok "F14 the shown names hold in the excludes"; else bad "F14 the shown names hold in the excludes (rc=$RC: ${ERR:0:200})"; fi

# F15 a long excludes line costs no real time, read one character at a time.
fresh
files 8 src
git add -A
head -c 1048576 /dev/zero | tr '\0' x >.fan-out-excludes
timeout 10 bash scripts/check-fan-out --all >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 124 ]; then ok "F15 a 1 MiB excludes line does not stall (rc=$RC)"; else bad "F15 a 1 MiB excludes line does not stall"; fi

# F16 a space that ends a folder's name: a line loses it, so the excludes take "?".
fresh
files 8 'y '
git add -A
fan --update-baseline
fan --all
if [ "$RC" -eq 0 ]; then ok "F16 the baseline holds for a space that ends a name"; else bad "F16 the baseline holds for a space that ends a name (rc=$RC: ${ERR:0:200})"; fi
rm .fan-out-baseline
fan_excludes 'y?'
fan --all
if [ "$RC" -eq 0 ]; then ok "F16 y? in the excludes matches it"; else bad "F16 y? in the excludes matches it (rc=$RC: ${ERR:0:200})"; fi

# F17 globs see a "#" or space that starts a path as itself, and ? one escaped character.
for pair in '#x|?x' '#x|**/#x' ' y|?y' ' y|**/ y'; do
  fresh
  files 8 "${pair%%|*}"
  git add -A
  fan_excludes "${pair#*|}"
  fan --all
  if [ "$RC" -eq 0 ]; then ok "F17 ${pair#*|} matches [${pair%%|*}]"; else bad "F17 ${pair#*|} matches [${pair%%|*}] (rc=$RC: ${ERR:0:200})"; fi
done
fresh
files 8 $'a\tb'
files 8 $'c\rd'
git add -A
fan_excludes 'a?b' 'c?d'
fan --all
if [ "$RC" -eq 0 ]; then ok "F17 ? matches a tab and a CR"; else bad "F17 ? matches a tab and a CR (rc=$RC: ${ERR:0:200})"; fi
fan_excludes $'a\tb' $'c\rd'
fan --all
if [ "$RC" -eq 0 ]; then ok "F17 a raw tab or CR holds in the excludes"; else bad "F17 a raw tab or CR holds in the excludes (rc=$RC: ${ERR:0:200})"; fi

# F18 a baseline line with a raw tab, from an older script, still holds and stays.
rm .fan-out-excludes
printf 'a\tb 8\nc\rd 8\n' >.fan-out-baseline
fan --all
if [ "$RC" -eq 0 ]; then ok "F18 a raw baseline line holds"; else bad "F18 a raw baseline line holds (rc=$RC: ${ERR:0:200})"; fi
fan --update-baseline
fan --all
if [ "$RC" -eq 0 ] && grep -qxF 'a\tb 8' .fan-out-baseline && grep -qxF 'c\rd 8' .fan-out-baseline; then
  ok "F18 update keeps a raw line, written as its escape"
else
  bad "F18 update keeps a raw line, written as its escape (rc=$RC: $(cat .fan-out-baseline))"
fi

# F19 a long excludes line stalls no awk.
fresh
files 8 src
git add -A
head -c 1048576 /dev/zero | tr '\0' a >.fan-out-excludes
for aw in mawk 'busybox awk'; do
  command -v "${aw%% *}" >/dev/null || continue
  mkdir -p "$WORK/awk$n"
  printf '#!/bin/sh\nexec %s "$@"\n' "$aw" >"$WORK/awk$n/awk"
  chmod 755 "$WORK/awk$n/awk"
  PATH="$WORK/awk$n:$PATH" timeout 10 bash scripts/check-fan-out --all >/dev/null 2>&1
  RC=$?
  if [ "$RC" -eq 1 ]; then ok "F19 $aw skips a 1 MiB excludes line"; else bad "F19 $aw skips a 1 MiB excludes line (rc=$RC)"; fi
done

# F20 ? takes one character of the name: never a "/" or half an escape.
fresh
files 8 'x\/b'
files 8 $'a\tb'
git add -A
fan_excludes 'x??b' 'a?tb'
fan --all
if [ "$RC" -eq 1 ] && grep -qF 'fan-out: x\\/b ' <<<"$ERR" && grep -qF 'fan-out: a\tb ' <<<"$ERR"; then
  ok "F20 ? crosses no / and splits no escape"
else
  bad "F20 ? crosses no / and splits no escape (rc=$RC: ${ERR:0:200})"
fi

# F21 a line of many wildcards costs no real time.
fresh
files 8 src
git add -A
for ch in '*' '?'; do
  head -c 4096 /dev/zero | tr '\0' "$ch" >.fan-out-excludes
  printf '\n' >>.fan-out-excludes
  head -c 512 /dev/zero | tr '\0' "$ch" >>.fan-out-excludes
  timeout 10 bash scripts/check-fan-out --all >/dev/null 2>&1
  RC=$?
  if [ "$RC" -ne 124 ]; then ok "F21 lines of $ch do not stall (rc=$RC)"; else bad "F21 lines of $ch do not stall"; fi
done

# Runs check-fan-out --all under awk $1 ("mawk", "busybox awk"), within 10 s.
fan_under() {
  local shim="$WORK/under-${1%% *}"
  mkdir -p "$shim"
  printf '#!/bin/sh\nexec %s "$@"\n' "$1" >"$shim/awk"
  chmod 755 "$shim/awk"
  ERR="$(PATH="$shim:$PATH" timeout 10 bash scripts/check-fan-out --all 2>&1 >/dev/null)"
  RC=$?
}
UNDER=()
for aw in gawk mawk 'busybox awk'; do command -v "${aw%% *}" >/dev/null && UNDER+=("$aw"); done

# F22 345: many "*" in one glob. Master stalled mawk on this past 60 s.
fresh
as="$(printf 'd/%.0s' $(seq 39))$(printf 'a%.0s' $(seq 200))"
files 8 "$as"
git add -A
for glob in '**/a*a*a*a*a*a*a*a*a*a*a*a*zz' "**/$(printf 'a*%.0s' $(seq 100))zz"; do
  printf '%s\n' "$glob" >.fan-out-excludes
  for aw in "${UNDER[@]}"; do
    fan_under "$aw"
    if [ "$RC" -eq 1 ]; then ok "F22 $aw: ${glob:0:20}... does not stall"; else bad "F22 $aw: ${glob:0:20}... does not stall (rc=$RC)"; fi
  done
done
printf '%s\n' '**/a*a*a*a*a*a*a*a*a*a*a*a' >.fan-out-excludes
for aw in "${UNDER[@]}"; do
  fan_under "$aw"
  if [ "$RC" -eq 0 ]; then ok "F22 $aw: many * that match skip the folder"; else bad "F22 $aw: many * that match skip the folder (rc=$RC)"; fi
done

# F23 345: "**" on a very deep path. Master took mawk 12 s at depth 400 and past 60 s
# at 1000. The literal between "**" gets past the check of the glob's end.
fresh
deep1000="$(printf 'd/%.0s' $(seq 1000))"
files 8 "${deep1000}zz"
files 8 "${deep1000%/}"
git add -A
# Each row: a glob and how many of the two folders stay reported.
for row in '**/**/**/**/zz|1' '**/d/**/d/**/d/**/zz|1' '**/d|1' '**/**/**/**/d/zz|1' '**/d/**/d/**/d/**/d|1' 'd/**|0' '**/**/**/**/yy|2' '**/d/**/d/**/d/**/yy|2'; do
  printf '%s\n' "${row%|*}" >.fan-out-excludes
  for aw in "${UNDER[@]}"; do
    fan_under "$aw"
    got=$(grep -c '^fan-out: ' <<<"$ERR")
    if [ "$RC" -ne 124 ] && [ "$got" -eq "${row#*|}" ]; then ok "F23 $aw: ${row%|*} at depth 1000"; else bad "F23 $aw: ${row%|*} at depth 1000 (rc=$RC, $got)"; fi
  done
done

# F24 345: each glob skips the folders it did on master, under every awk. The rows
# came from master's regexes, and all three awks agreed on them.
fresh
dirs=(a/b a/b/c ab axb a.b 'x[y' 'x^y' 'x$y' 'x(y)' 'x|y' 'x+y' 'x{y}' 'x*y' 'x?y' $'l\nm' $'t\tu' 'p\q' '#h' ' s' 'zz/a/b')
shown=(a/b a/b/c ab axb a.b 'x[y' 'x^y' 'x$y' 'x(y)' 'x|y' 'x+y' 'x{y}' 'x*y' 'x?y' 'l\nm' 't\tu' 'p\\q' '\#h' '\ss' 'zz/a/b')
for d in "${dirs[@]}"; do files 8 "$d"; done
git add -A
while IFS='~' read -r glob want; do
  printf '%s\n' "$glob" >.fan-out-excludes
  for aw in "${UNDER[@]}"; do
    fan_under "$aw"
    got=""
    for s in "${shown[@]}"; do grep -qF "fan-out: $s holds" <<<"$ERR" || got="$got $s"; done
    if [ "$got" = "${want:+ }$want" ]; then ok "F24 $aw: $glob"; else bad "F24 $aw: $glob (got:$got)"; fi
  done
done <<'ROWS'
a*b~ab axb a.b
a*?*b~axb a.b
a?b~axb a.b
a**b~a/b ab axb a.b
a**/b~a/b ab
a/**~a/b a/b/c
**/b~a/b zz/a/b
**/a/**~a/b a/b/c zz/a/b
**/**/c~a/b/c
a/***~a/b a/b/c
***/b~a/b zz/a/b
****/c~a/b/c
a/*~a/b
*/b~a/b
*~ab axb a.b x[y x^y x$y x(y) x|y x+y x{y} x*y x?y l\nm t\tu p\\q \#h \ss
?~
**~a/b a/b/c ab axb a.b x[y x^y x$y x(y) x|y x+y x{y} x*y x?y l\nm t\tu p\\q \#h \ss zz/a/b
x[y~x[y
x[[]y~
x^y~x^y
^x~
x$y~x$y
x$~
x?y~x[y x^y x$y x|y x+y x*y x?y
x\*y~
x*y~x[y x^y x$y x|y x+y x*y x?y
x.y~
a.b~a.b
x(y)~x(y)
x|y~x|y
x+y~x+y
x{y}~x{y}
x???~x(y) x{y}
l\nm~l\nm
l?m~l\nm
l*m~l\nm
t\tu~t\tu
t?u~t\tu
p\\q~p\\q
p?q~p\\q
p??q~
\#h~\#h
#h~
?h~\#h
\ss~\ss
 s~
?s~\ss
**/#h~\#h
a/b/~
a**~a/b a/b/c ab axb a.b
zz/**/b~zz/a/b
zz**/b~zz/a/b
z*/*/b~zz/a/b
ROWS

# F25 353: in UTF-8 "?" takes one byte under each awk, as in git, so a two-byte name
# takes "??". A name that is not UTF-8 matches too.
fresh
files 8 'ä'
files 8 $'b\xff'
git add -A
for aw in "${UNDER[@]}"; do
  printf '%s\n' '??' 'b*' >.fan-out-excludes
  LC_ALL=C.UTF-8 fan_under "$aw"
  if [ "$RC" -eq 0 ]; then ok "F25 353 $aw: ?? is the UTF-8 name"; else bad "F25 353 $aw: ?? is the UTF-8 name (${ERR:0:90})"; fi
  printf '%s\n' '?' 'b*' >.fan-out-excludes
  LC_ALL=C.UTF-8 fan_under "$aw"
  if [ "$RC" -eq 1 ]; then ok "F25 353 $aw: ? is not the UTF-8 name"; else bad "F25 353 $aw: ? is not the UTF-8 name (rc=$RC)"; fi
done
