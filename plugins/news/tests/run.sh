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
printf '%s\n' '#!/bin/bash' 'printf "%s\n" "$@" >"$HOME/args"' 'echo "$SHELL" >"$HOME/shell"' \
  '[ -n "${NO_PAGE:-}" ] || { mkdir -p "$(dirname "$PAGE")"; echo page >"$PAGE"; }' >"$T/home/.local/bin/claude"
chmod +x "$T/home/.local/bin/claude"
cron() { env -u KASTEN_PERIODIC_PATH -u NEWS_PLUGIN_DIR HOME="$T/home" NEWS_LOG_DIR="$T/log" "$@" "$here/../scripts/cron-edition.sh" "$V"; }

# cron wrapper: permissions skipped, the periodic folder from kasten's variable, exit 1 with no page
cron KASTEN_PERIODIC_PATH=P PAGE="$V/P/05 Newspaper/$DAY.html"; ok "cron exit" $? 0
has "cron skips permissions" "$(cat "$T/home/args")" "--dangerously-skip-permissions"
has "cron passes the periodic folder" "$(cat "$T/home/args")" '--periodic "P"'
# cron sets SHELL=/bin/sh; claude must see bash, or its Bash tool runs zsh
cron SHELL=/bin/sh KASTEN_PERIODIC_PATH=P PAGE="$V/P/05 Newspaper/$DAY.html"; ok "cron hands claude bash" "$(cat "$T/home/shell")" /bin/bash
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

# render: heimatblatt opts in to kasten's theme, keeps colour and fonts in tokens, and stacks below 640 px
printf 'design: heimatblatt\n' >"$NP/config/design.yaml"
edition https://example.org/bridge 2026-10-18 2026-10-13T09:00:00+02:00
out=$(uv run -q "$S/render.py" --vault "$RV" --date 2026-10-19 --out "$T/news.html" 2>&1); ok "render exit" $? 0
has "render names the design" "$out" "design 'heimatblatt'"
has "page opts in to kasten's theme" "$(cat "$T/news.html")" '<meta name="kasten-theme" content="tokens">'
ok "page loads no fonts" "$(grep -c 'fonts.googleapis' "$T/news.html")" 0
# the CSS outside the fallback layer: from the first <style> to the layer, then after the layer
awk '/<style>/{s=1} /^@layer kasten-fallback/{skip=1} s && !skip{print} skip && /^\}$/{skip=0} /<\/style>/{s=0}' "$T/news.html" >"$T/news-css.txt"
ok "no hex outside the fallback layer" "$(grep -c '#[0-9a-fA-F]\{3,8\}' "$T/news-css.txt")" 0
ok "no rgb() outside the fallback layer" "$(grep -c 'rgb(' "$T/news-css.txt")" 0
ok "no quoted font family outside the fallback layer" "$(grep -c 'font[^;]*"' "$T/news-css.txt")" 0
has "one column below 640 px" "$(cat "$T/news-css.txt")" "@media (max-width:639px)"
has "fallback layer has the dark tokens" "$(cat "$T/news.html")" '@media (prefers-color-scheme: dark) {'

# a bracket on the lead: RECORD fills both matches' record, empty for a knockout
bracket() {
  python3 - "$NP/2026-10-19.json" "$1" <<'PY'
import json, sys
path, rec = sys.argv[1], sys.argv[2] or None
e = json.load(open(path))
m = lambda a, b, s, w: {"a": a, "b": b, "score": s, "winner": w, "when": None, "record": rec}
e["lead"]["bracket"] = {"tags": {"Gen.G": "GEN", "T1": "T1"}, "rounds": [
    {"name": "Semis", "matches": [m("Gen.G", "Top Esports", "3-1", "a"), m("T1", "Invictus Gaming", "3-2", "a")]},
    {"name": "Final", "matches": [m("Gen.G", "T1", None, None)]}]}
json.dump(e, open(path, "w"))
PY
}
edition https://example.org/bridge 2026-10-18 2026-10-13
bracket 2-1
out=$(validate); ok "validate swiss bracket exit" $? 0
bracket 2:1
out=$(validate); ok "validate bad record exit" $? 1
has "validate bad record names it" "$out" 'record must be like "2-1" or null'
render() { uv run -q "$S/render.py" --vault "$RV" --date 2026-10-19 --design tabbed --out "$T/b.html" >/dev/null 2>&1; cat "$T/b.html"; }
bracket 2-1
out=$(render)
has "swiss bracket class" "$out" 'class="bracket swiss"'
has "swiss record band" "$out" '<h5 class="rec">2-1<span class="pips"><i class="w"></i><i class="w"></i><i class="l"></i></span></h5>'
has "team tag" "$out" '<span class="tag">GEN</span>'
bracket ""
out=$(render)
has "knockout bracket class" "$out" 'class="bracket ko"'
has "knockout joins pairs" "$out" '<div class="round pairs">'
ok "knockout has no record band" "$(grep -c 'class="rec"' <<<"$out")" 0

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
