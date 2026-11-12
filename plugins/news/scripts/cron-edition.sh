#!/bin/bash
# Build today's newspaper edition headless. Cron entry point:
#   0 6 * * * /path/to/plugins/news/scripts/cron-edition.sh /path/to/vault
# Cron runs at the host's local time; on a host not set to Europe/Berlin, put
# CRON_TZ=Europe/Berlin above the line (cronie) or use a systemd timer.
# NEWS_MODEL and NEWS_EFFORT pick the model and effort (default opus, medium),
# so a change to the interactive default does not change this job.
# NEWS_PLUGIN_DIR=/path/to/plugins/news loads the plugin from that working
# tree instead of the installed one, to test a change the way cron runs it.
set -uo pipefail

VAULT="${1:?usage: cron-edition.sh VAULT_PATH}"
VAULT="$(cd "$VAULT" && pwd)" || exit 1

# Cron has a minimal PATH; claude and uv live in ~/.local/bin, and bunx, which
# a statusline hook calls on every prompt, in ~/.bun/bin.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"

# Cron sets SHELL=/bin/sh, so Claude Code would pick zsh for its Bash tool;
# zsh aborts a command on an unmatched ? or * (unquoted URLs). Use bash.
export SHELL=/bin/bash

LOG_DIR="${NEWS_LOG_DIR:-$HOME/.local/state/news}"
mkdir -p "$LOG_DIR"
DAY="$(TZ=Europe/Berlin date +%F)"
LOG="$LOG_DIR/$DAY.log"
PERIODIC="${KASTEN_PERIODIC_PATH:-01 Periodic}"

cd "$VAULT" || exit 1
echo "== $(date -Is) edition $DAY for $VAULT" >>"$LOG"

PLUGIN=()
[ -n "${NEWS_PLUGIN_DIR:-}" ] && PLUGIN=(--plugin-dir "$NEWS_PLUGIN_DIR")

# The stamp marks the run's start, so a page left by an earlier run fails.
STAMP="$(mktemp)"
trap 'rm -f "$STAMP"' EXIT

# -p prompts nobody, so the session runs with permissions skipped.
claude -p "/news:edition --vault \"$VAULT\" --periodic \"$PERIODIC\" --date $DAY" "${PLUGIN[@]}" \
  --model "${NEWS_MODEL:-opus}" --effort "${NEWS_EFFORT:-medium}" \
  --dangerously-skip-permissions \
  >>"$LOG" 2>&1
status=$?

# claude can exit 0 without having finished: a turn that ends in plain text
# ends the run. The edition is done only when this run wrote the page, memory
# holds the day (or tomorrow repeats today's stories) and the daily note links it.
NP="$VAULT/$PERIODIC/05 Newspaper"
EDITION="$NP/$DAY.html"
NOTE="$VAULT/$PERIODIC/00 Daily/$DAY.md"
if [ "$status" -eq 0 ]; then
  if [ ! -s "$EDITION" ] || [ ! "$EDITION" -nt "$STAMP" ]; then
    echo "== no edition from this run at $EDITION" >>"$LOG"
    status=1
  elif ! grep -q "\"date\": *\"$DAY\"" "$NP/memory/stories.jsonl" 2>/dev/null; then
    echo "== edition written but not remembered in $NP/memory/stories.jsonl" >>"$LOG"
    status=1
  elif ! grep -qF "[[$PERIODIC/05 Newspaper/$DAY.html]]" "$NOTE" 2>/dev/null; then
    echo "== edition written but no link in $NOTE" >>"$LOG"
    status=1
  fi
fi
echo "== $(date -Is) exit $status" >>"$LOG"
exit "$status"
