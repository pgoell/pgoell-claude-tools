---
type: How-to Guide
title: Schedule insights
description: Have cron write the insights digest and activity pages in your kasten vault every morning, before the newspaper.
tags: [insights, cron, kasten, setup]
status: stable
---

# Schedule insights

`/insights:digest` writes the day's problems and proposed fixes under `<periodic>/06 Insights/`, and `/insights:activity` writes what the agents did under `<periodic>/07 Activity/`, both in a kasten vault. This page runs them at 05:30 and 05:45, before the 06:00 newspaper, so all three links land in the same daily note.

## Before you start

- `uv` and `claude` in `~/.local/bin` or `/usr/local/bin`; the wrappers set a short `PATH` for cron.
- `git` and a logged-in `gh` (`gh auth status`), for the pull requests `/insights:apply` opens and the counts on the activity page.
- `bunx` in `~/.bun/bin`, for `ccusage`, which the activity page uses for tokens and cost.
- The `insights` plugin installed in Claude Code. The wrappers call the installed plugin.
- A clone of this repository on the host (`<clone>` below) and your vault path (`<vault>`).

## Steps

1. Open the crontab with `crontab -e` and add:

   ```
   30 5 * * * <clone>/plugins/insights/scripts/cron-insights.sh <vault>
   45 5 * * * <clone>/plugins/insights/scripts/cron-activity.sh <vault>
   ```

   Cron runs at the host's local time. On a host not set to Europe/Berlin, put `CRON_TZ=Europe/Berlin` above the lines.

Each wrapper runs its skill for yesterday through `claude -p` with permissions skipped (`--dangerously-skip-permissions`). The activity job stops after 30 minutes.

## Check it worked

- Run a wrapper by hand once: `<clone>/plugins/insights/scripts/cron-insights.sh <vault>`.
- The pages `<vault>/01 Periodic/06 Insights/<yesterday>.html` and `.../07 Activity/<yesterday>.html` exist, linked from today's daily note.
- Logs are in `~/.local/state/insights/`: `<date>.log` for the digest and `<date>-activity.log` for the activity page (`INSIGHTS_LOG_DIR` moves them). A wrapper exits non-zero when claude fails or wrote no page.

After you review a digest, `/insights:apply` carries out the fixes you kept. See [the insights reference page](/reference/plugins/insights.md) and the [plugin README](../../plugins/insights/README.md).
