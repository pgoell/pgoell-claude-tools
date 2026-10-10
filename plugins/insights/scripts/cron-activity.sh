#!/bin/bash
# Build yesterday's agent activity page headless. Cron entry point:
#   45 5 * * * /path/to/plugins/insights/scripts/cron-activity.sh /path/to/vault
# 05:45 runs between the 05:30 insights job and the 06:00 newspaper, so all
# three links land in the same daily note. Cron runs at the host's local
# time; on a host not set to Europe/Berlin, put CRON_TZ=Europe/Berlin above
# the line.
# INSIGHTS_PLUGIN_DIR=/path/to/plugins/insights loads the plugin from that
# working tree instead of the installed one, to test a change the way cron runs it.
set -uo pipefail

VAULT="${1:?usage: cron-activity.sh VAULT_PATH}"
VAULT="$(cd "$VAULT" && pwd)" || exit 1

# Cron has a minimal PATH; claude and uv live in ~/.local/bin, and bunx, which
# runs ccusage, in ~/.bun/bin.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"

LOG_DIR="${INSIGHTS_LOG_DIR:-$HOME/.local/state/insights}"
mkdir -p "$LOG_DIR"
TODAY="$(TZ=Europe/Berlin date +%F)"
DAY="$(TZ=Europe/Berlin date -d yesterday +%F)"
LOG="$LOG_DIR/$TODAY-activity.log"

cd "$VAULT" || exit 1
echo "== $(date -Is) activity for $DAY in $VAULT" >>"$LOG"

PLUGIN=()
[ -n "${INSIGHTS_PLUGIN_DIR:-}" ] && PLUGIN=(--plugin-dir "$INSIGHTS_PLUGIN_DIR")

# -p prompts nobody, so every tool the skill needs is allowed up front: uv for
# the scripts, which call git, gh and bunx themselves.
# insights-self-run marks this session, so tomorrow's runs leave it out.
claude -p "/insights:activity --vault \"$VAULT\" --date $DAY insights-self-run" "${PLUGIN[@]}" \
  --allowedTools "Read" "Write" "Edit" "Glob" "Grep" \
  "Bash(uv run:*)" "Bash(bunx:*)" "Bash(git:*)" "Bash(gh:*)" "Bash(jq:*)" "Bash(ls:*)" "Bash(cat:*)" \
  "Bash(head:*)" "Bash(wc:*)" "Bash(command -v:*)" "Bash(date:*)" \
  >>"$LOG" 2>&1
status=$?

# claude can exit 0 without having written the page; the file is the real check.
PAGE="$VAULT/${INSIGHTS_PERIODIC:-01 Periodic}/07 Activity/$DAY.html"
if [ "$status" -eq 0 ] && [ ! -s "$PAGE" ]; then
  echo "== no page at $PAGE" >>"$LOG"
  status=1
fi
echo "== $(date -Is) exit $status" >>"$LOG"
exit "$status"
