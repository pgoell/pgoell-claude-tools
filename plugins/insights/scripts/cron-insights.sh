#!/bin/bash
# Analyse yesterday's Claude Code sessions headless. Cron entry point:
#   30 5 * * * /path/to/plugins/insights/scripts/cron-insights.sh /path/to/vault
# 05:30 runs before the 06:00 newspaper, so both links land in the same
# daily note. Cron runs at the host's local time; on a host not set to
# Europe/Berlin, put CRON_TZ=Europe/Berlin above the line.
# INSIGHTS_MODEL and INSIGHTS_EFFORT pick the model and effort (default fable,
# high): the digest writes standing rules, and an unset effort would follow
# whatever the interactive default is today.
# INSIGHTS_PLUGIN_DIR=/path/to/plugins/insights loads the plugin from that
# working tree instead of the installed one, to test a change the way cron runs it.
set -uo pipefail

VAULT="${1:?usage: cron-insights.sh VAULT_PATH}"
VAULT="$(cd "$VAULT" && pwd)" || exit 1

# Cron has a minimal PATH; claude and uv live in ~/.local/bin, and bunx, which
# a statusline hook calls on every prompt, in ~/.bun/bin.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"

# Cron sets SHELL=/bin/sh, so Claude Code would pick zsh for its Bash tool;
# zsh aborts a command on an unmatched ? or * (unquoted URLs). Use bash.
export SHELL=/bin/bash

LOG_DIR="${INSIGHTS_LOG_DIR:-$HOME/.local/state/insights}"
mkdir -p "$LOG_DIR"
TODAY="$(TZ=Europe/Berlin date +%F)"
DAY="$(TZ=Europe/Berlin date -d yesterday +%F)"
LOG="$LOG_DIR/$TODAY.log"
PERIODIC="${KASTEN_PERIODIC_PATH:-01 Periodic}"

cd "$VAULT" || exit 1
echo "== $(date -Is) insights for $DAY in $VAULT" >>"$LOG"

PLUGIN=()
[ -n "${INSIGHTS_PLUGIN_DIR:-}" ] && PLUGIN=(--plugin-dir "$INSIGHTS_PLUGIN_DIR")

# The stamp marks the run's start, so a page left by an earlier run fails.
STAMP="$(mktemp)"
trap 'rm -f "$STAMP"' EXIT

# -p prompts nobody, so the session runs with permissions skipped.
# insights-self-run marks this session, so tomorrow's extract skips it.
claude -p "/insights:digest --vault \"$VAULT\" --periodic \"$PERIODIC\" --date $DAY insights-self-run" "${PLUGIN[@]}" \
  --model "${INSIGHTS_MODEL:-fable}" --effort "${INSIGHTS_EFFORT:-high}" \
  --dangerously-skip-permissions \
  >>"$LOG" 2>&1
status=$?

# claude can exit 0 without having finished: a turn that ends in plain text
# ends the run. The link in today's daily note is the protocol's last write,
# so check it beside a page written by this run.
PAGE="$VAULT/$PERIODIC/06 Insights/$DAY.html"
NOTE="$VAULT/$PERIODIC/00 Daily/$TODAY.md"
if [ "$status" -eq 0 ]; then
  if [ ! -s "$PAGE" ] || [ ! "$PAGE" -nt "$STAMP" ]; then
    echo "== no page from this run at $PAGE" >>"$LOG"
    status=1
  elif ! grep -qF "[[$PERIODIC/06 Insights/$DAY.html]]" "$NOTE" 2>/dev/null; then
    echo "== page written but no link in $NOTE" >>"$LOG"
    status=1
  fi
fi
echo "== $(date -Is) exit $status" >>"$LOG"
exit "$status"
