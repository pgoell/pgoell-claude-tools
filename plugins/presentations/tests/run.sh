#!/usr/bin/env bash
# Tests that <deck-stage> survives being removed and re-added (issue #222):
# loads fixtures/readd.html in headless Chrome and reads the results the
# page writes into #result. No network.
# Run from anywhere: bash plugins/presentations/tests/run.sh [assets-dir]
# assets-dir defaults to this plugin's creating-presentations/assets; pass
# another copy of the engine to run the cases against it.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$(cd "${1:-$HERE/../skills/creating-presentations/assets}" && pwd)"
FIXTURE="$HERE/fixtures/readd.html"
CASES=(first-mount readd-shadow readd-slot readd-thumbs readd-keys readd-rail-state)

CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
if [ -z "$CHROME" ]; then
  echo "FAIL no headless Chrome found (tried google-chrome, chromium, chromium-browser)"
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The fixture holds the page's load event, and so the dump, until every
# case has reported (eight waits of at most 3s each when every case
# fails); --timeout only bounds a page that hangs.
results="$("$CHROME" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
  --user-data-dir="$WORK" --host-resolver-rules='MAP * ~NOTFOUND' \
  --allow-file-access-from-files --timeout=60000 --dump-dom \
  "file://$FIXTURE?assets=file://$ASSETS/" 2>&1 |
  grep -oE '^[a-z-]+: (PASS|FAIL)[^<]*' || true)"

pass=0
fail=0
for name in "${CASES[@]}"; do
  line="$(grep -E "^$name: " <<<"$results" || true)"
  if [ -z "$line" ]; then
    echo "$name: FAIL no result"
    fail=$((fail + 1))
  elif grep -q ': PASS' <<<"$line"; then
    echo "$line"
    pass=$((pass + 1))
  else
    echo "$line"
    fail=$((fail + 1))
  fi
done
# A script error in the page reports as "error: FAIL ...".
if grep -E '^error: ' <<<"$results"; then fail=$((fail + 1)); fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
