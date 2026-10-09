#!/bin/bash
# Analyse yesterday's Claude Code sessions headless. Cron entry point:
#   30 5 * * * /path/to/plugins/insights/scripts/cron-insights.sh /path/to/vault
# 05:30 runs before the 06:00 newspaper, so both links land in the same
# daily note. Cron runs at the host's local time; on a host not set to
# Europe/Berlin, put CRON_TZ=Europe/Berlin above the line.
# INSIGHTS_PLUGIN_DIR=/path/to/plugins/insights loads the plugin from that
# working tree instead of the installed one, to test a change the way cron runs it.
set -uo pipefail

VAULT="${1:?usage: cron-insights.sh VAULT_PATH}"
VAULT="$(cd "$VAULT" && pwd)" || exit 1

# Cron has a minimal PATH; claude and uv live in ~/.local/bin, and bunx, which
# a statusline hook calls on every prompt, in ~/.bun/bin.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"

LOG_DIR="${INSIGHTS_LOG_DIR:-$HOME/.local/state/insights}"
mkdir -p "$LOG_DIR"
TODAY="$(TZ=Europe/Berlin date +%F)"
DAY="$(TZ=Europe/Berlin date -d yesterday +%F)"
LOG="$LOG_DIR/$TODAY.log"

cd "$VAULT" || exit 1
echo "== $(date -Is) insights for $DAY in $VAULT" >>"$LOG"

PLUGIN=()
[ -n "${INSIGHTS_PLUGIN_DIR:-}" ] && PLUGIN=(--plugin-dir "$INSIGHTS_PLUGIN_DIR")

# -p prompts nobody, so every tool the digest and apply steps need is allowed
# up front: uv for the scripts, rg and ps to check causes, git and gh for PRs.
# insights-self-run marks this session, so tomorrow's extract skips it.
claude -p "/insights:digest --vault \"$VAULT\" --date $DAY insights-self-run" "${PLUGIN[@]}" \
  --allowedTools "Read" "Write" "Edit" "Glob" "Grep" \
  "Bash(uv run:*)" "Bash(rg:*)" "Bash(grep:*)" "Bash(ps:*)" "Bash(pgrep:*)" "Bash(ls:*)" "Bash(cat:*)" \
  "Bash(head:*)" "Bash(wc:*)" "Bash(command -v:*)" "Bash(date:*)" "Bash(mkdir:*)" "Bash(jq:*)" \
  "Bash(git:*)" "Bash(gh:*)" "Bash(dprint:*)" "Bash(mise:*)" \
  >>"$LOG" 2>&1
status=$?

# claude can exit 0 without having written the page; the file is the real check.
PAGE="$VAULT/${INSIGHTS_PERIODIC:-01 Periodic}/06 Insights/$DAY.html"
if [ "$status" -eq 0 ] && [ ! -s "$PAGE" ]; then
  echo "== no page at $PAGE" >>"$LOG"
  status=1
fi
echo "== $(date -Is) exit $status" >>"$LOG"
exit "$status"
