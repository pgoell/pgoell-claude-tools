#!/bin/bash
# Build today's newspaper edition headless. Cron entry point:
#   0 6 * * * /path/to/plugins/news/scripts/cron-edition.sh /path/to/vault
# Cron runs at the host's local time; on a host not set to Europe/Berlin, put
# CRON_TZ=Europe/Berlin above the line (cronie) or use a systemd timer.
# NEWS_PLUGIN_DIR=/path/to/plugins/news loads the plugin from that working
# tree instead of the installed one, to test a change the way cron runs it.
set -uo pipefail

VAULT="${1:?usage: cron-edition.sh VAULT_PATH}"
VAULT="$(cd "$VAULT" && pwd)" || exit 1

# Cron has a minimal PATH; claude and uv live in ~/.local/bin, and bunx, which
# a statusline hook calls on every prompt, in ~/.bun/bin.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"

LOG_DIR="${NEWS_LOG_DIR:-$HOME/.local/state/news}"
mkdir -p "$LOG_DIR"
DAY="$(TZ=Europe/Berlin date +%F)"
LOG="$LOG_DIR/$DAY.log"
PERIODIC="${KASTEN_PERIODIC_PATH:-01 Periodic}"

cd "$VAULT" || exit 1
echo "== $(date -Is) edition $DAY for $VAULT" >>"$LOG"

PLUGIN=()
[ -n "${NEWS_PLUGIN_DIR:-}" ] && PLUGIN=(--plugin-dir "$NEWS_PLUGIN_DIR")

# -p prompts nobody, so the session runs with permissions skipped.
claude -p "/news:edition --vault \"$VAULT\" --periodic \"$PERIODIC\" --date $DAY" "${PLUGIN[@]}" \
  --dangerously-skip-permissions \
  >>"$LOG" 2>&1
status=$?

# claude can exit 0 without having written the paper; the file is the real check.
EDITION="$VAULT/$PERIODIC/05 Newspaper/$DAY.html"
if [ "$status" -eq 0 ] && [ ! -s "$EDITION" ]; then
  echo "== no edition at $EDITION" >>"$LOG"
  status=1
fi
echo "== $(date -Is) exit $status" >>"$LOG"
exit "$status"
