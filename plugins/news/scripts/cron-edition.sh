#!/bin/bash
# Build today's newspaper edition headless. Cron entry point:
#   0 6 * * * /path/to/plugins/news/scripts/cron-edition.sh /path/to/vault
# Cron runs at the host's local time; on a host not set to Europe/Berlin, put
# CRON_TZ=Europe/Berlin above the line (cronie) or use a systemd timer.
set -uo pipefail

VAULT="${1:?usage: cron-edition.sh VAULT_PATH}"
VAULT="$(cd "$VAULT" && pwd)" || exit 1

# Cron has a minimal PATH; claude and uv live in ~/.local/bin.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

LOG_DIR="${NEWS_LOG_DIR:-$HOME/.local/state/news}"
mkdir -p "$LOG_DIR"
DAY="$(TZ=Europe/Berlin date +%F)"
LOG="$LOG_DIR/$DAY.log"

cd "$VAULT" || exit 1
echo "== $(date -Is) edition $DAY for $VAULT" >>"$LOG"

# -p prompts nobody, so every tool the edition needs is allowed up front.
claude -p "/news:edition --vault \"$VAULT\" --date $DAY" \
  --allowedTools "Read" "Write" "Edit" "Glob" "Grep" "WebSearch" "WebFetch" "Agent" \
  "Bash(uv run:*)" "Bash(curl:*)" "Bash(python3:*)" "Bash(date:*)" "Bash(ls:*)" "Bash(mkdir:*)" \
  >>"$LOG" 2>&1
status=$?

# claude can exit 0 without having written the paper; the file is the real check.
EDITION="$VAULT/${NEWS_PERIODIC:-01 Periodic}/05 Newspaper/$DAY.html"
if [ "$status" -eq 0 ] && [ ! -s "$EDITION" ]; then
  echo "== no edition at $EDITION" >>"$LOG"
  status=1
fi
echo "== $(date -Is) exit $status" >>"$LOG"
exit "$status"
