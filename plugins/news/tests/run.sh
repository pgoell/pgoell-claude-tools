#!/bin/bash
# usage: tests/run.sh
# Runs the cron wrapper with a fake claude in a temp home and a temp vault,
# validate.py's freshness check on fixture editions, and refetch.py against a
# closed port and a local http.server. No session, no outside network, no real
# crontab or vault. Needs bash, python3 and uv.
set -u
here=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d)
srv=
trap 'kill ${srv:-} 2>/dev/null; rm -rf "$T"' EXIT
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

# validate.py: published must lie in [edition date - freshness_days, edition date], Berlin days.
# The fixture's evals section has freshness_days 7, the top level 2; the lead has no section.
S="$here/../skills/edition/scripts"
RV="$T/rv"
NP="$RV/01 Periodic/05 Newspaper"
mkdir -p "$NP/config"
cp "$here/fixtures/topics.yaml" "$NP/config/topics.yaml"
edition() { sed -e "s|LEAD_URL|$1|" -e "s|LEAD_PUB|$2|" -e "s|STORY_PUB|$3|" "$here/fixtures/edition.json" >"$NP/2026-10-19.json"; }
validate() { uv run -q "$S/validate.py" "$NP/2026-10-19.json" "$@" 2>&1; }
edition https://example.org/bridge 2026-10-18 2026-10-13T09:00:00+02:00
out=$(validate); ok "validate fresh exit" $? 0
has "validate fresh has no errors" "$out" "0 errors"
edition https://example.org/bridge 2026-10-18 2026-10-11T09:00:00+02:00
out=$(validate); ok "validate stale exit" $? 1
has "validate stale names freshness" "$out" "2026-10-19-evals-01: published 2026-10-11 is older than section evals (freshness_days 7) allows; the window starts 2026-10-12"
edition https://example.org/bridge 2026-10-20T07:00:00+02:00 2026-10-13
out=$(validate); ok "validate future exit" $? 1
has "validate future names the date" "$out" "2026-10-19-bridge-01: published 2026-10-20 is after the edition date 2026-10-19"
out=$(validate --config "$T/none.yaml"); ok "validate without config exit" $? 0
has "validate without config warns" "$out" "published dates not checked against freshness_days"

# refetch.py: a closed port or a 404 is a dead lead, a 403 is a refusal (exit 2),
# a live page prints its text without scripts, a paywalled page its og meta
refetch() { uv run -q "$S/refetch.py" --vault "$RV" --date 2026-10-19 2>&1; }
edition http://127.0.0.1:1/ 2026-10-18 2026-10-13
out=$(refetch); ok "refetch dead exit" $? 1
has "refetch dead names the url" "$out" "error: lead url http://127.0.0.1:1/ is dead: refused"
: >"$T/srv.log"
python3 -u "$here/fixtures/server.py" >"$T/srv.log" 2>&1 &
srv=$!
port= n=0
while [ -z "$port" ] && [ "$n" -lt 20000 ]; do port=$(sed -n 's/.*port \([0-9]*\).*/\1/p' "$T/srv.log"); n=$((n + 1)); done
edition "http://127.0.0.1:$port/lead.html" 2026-10-18 2026-10-13
out=$(refetch); ok "refetch live exit" $? 0
has "refetch live prints the page" "$out" "The new bridge over the Kinzig cost twelve million euros."
ok "refetch live drops scripts" "$(grep -c SCRIPT_TEXT <<<"$out")" 0
edition "http://127.0.0.1:$port/missing.html" 2026-10-18 2026-10-13
out=$(refetch); ok "refetch 404 exit" $? 1
has "refetch 404 is dead" "$out" "error: lead url http://127.0.0.1:$port/missing.html is dead: 404"
edition "http://127.0.0.1:$port/blocked" 2026-10-18 2026-10-13
out=$(refetch); ok "refetch 403 exit" $? 2
has "refetch 403 is a refusal" "$out" "error: lead url http://127.0.0.1:$port/blocked refused the fetch: HTTP 403"
edition "http://127.0.0.1:$port/paywall.html" 2026-10-18 2026-10-13
out=$(refetch); ok "refetch paywall exit" $? 0
has "refetch paywall prints og:description" "$out" "og:description: The bridge cost twelve million euros and took two years."

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
