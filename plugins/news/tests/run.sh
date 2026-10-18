#!/bin/bash
# usage: tests/run.sh
# Runs the cron wrapper with a fake claude in a temp home and a temp vault.
# No session, no network, no real crontab or vault. Needs bash.
set -u
here=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got '$2', want '$3'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: no '$3' in: $2"; fi; }

V="$T/vault"
DAY=$(TZ=Europe/Berlin date +%F)
mkdir -p "$V" "$T/home/.local/bin"
# the fake records its args and writes the page at $PAGE unless NO_PAGE is set
printf '%s\n' '#!/bin/bash' 'printf "%s\n" "$@" >"$HOME/args"' \
  '[ -n "${NO_PAGE:-}" ] || { mkdir -p "$(dirname "$PAGE")"; echo page >"$PAGE"; }' >"$T/home/.local/bin/claude"
chmod +x "$T/home/.local/bin/claude"
cron() { env -u KASTEN_PERIODIC_PATH -u NEWS_PLUGIN_DIR HOME="$T/home" NEWS_LOG_DIR="$T/log" "$@" "$here/../scripts/cron-edition.sh" "$V"; }

# cron wrapper: permissions skipped, the periodic folder from kasten's variable, exit 1 with no page
cron KASTEN_PERIODIC_PATH=P PAGE="$V/P/05 Newspaper/$DAY.html"; ok "cron exit" $? 0
has "cron skips permissions" "$(cat "$T/home/args")" "--dangerously-skip-permissions"
has "cron passes the periodic folder" "$(cat "$T/home/args")" '--periodic "P"'
rm "$V/P/05 Newspaper/"*.html
cron KASTEN_PERIODIC_PATH=P PAGE="$V/P/05 Newspaper/$DAY.html" NO_PAGE=1; ok "cron exit with no page" $? 1
# without the variable the wrapper looks in 01 Periodic
cron PAGE="$V/01 Periodic/05 Newspaper/$DAY.html"; ok "cron exit in the default folder" $? 0
has "cron passes the default folder" "$(cat "$T/home/args")" '--periodic "01 Periodic"'

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
