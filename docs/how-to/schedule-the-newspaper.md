---
type: How-to Guide
title: Schedule the newspaper
description: Have cron build the news plugin's daily edition in your kasten vault every morning.
tags: [news, cron, kasten, setup]
status: stable
---

# Schedule the newspaper

`/news:edition` builds one HTML page per day under `<periodic>/05 Newspaper/` in a kasten vault. This page assumes the default periodic folder, `01 Periodic`: the wrapper looks for the page there. You can run it by hand; this page sets it up to run at 06:00 every morning.

## Before you start

- `uv` and `claude` on the host, both in `~/.local/bin` or `/usr/local/bin`: the wrapper sets a short `PATH` for cron.
- The `news` plugin installed in Claude Code. The wrapper calls the installed plugin.
- A clone of this repository on the host (`<clone>` below), for the wrapper script.
- Your vault path (`<vault>` below).

The edition uses the host's web search and fetch tools. The scripts make two requests of their own: the day's forecast from Open-Meteo (free, no key) and, for a section that lists `tables:`, league tables from sportschau.de.

## Steps

1. Build one edition by hand first. The first run seeds the config, feedback note and memory in the vault:

   ```bash
   <clone>/plugins/news/scripts/cron-edition.sh <vault>
   ```

2. Open the crontab with `crontab -e` and add:

   ```
   0 6 * * * <clone>/plugins/news/scripts/cron-edition.sh <vault>
   ```

   Cron runs at the host's local time. On a host not set to Europe/Berlin, put `CRON_TZ=Europe/Berlin` on the line above.

The wrapper runs `claude -p "/news:edition --vault <vault> --date <today>"` with permissions skipped (`--dangerously-skip-permissions`), since nobody is there to answer a prompt.

## Check it worked

- The page `<vault>/01 Periodic/05 Newspaper/<date>.html` exists, and the day's daily note links it.
- The log is `~/.local/state/news/<date>.log` (`NEWS_LOG_DIR` moves it). The wrapper exits non-zero when claude fails or wrote no edition.

To change what the paper covers, use `/news:feedback` or `/news:tune`. See [the news reference page](/reference/plugins/news.md) and the [plugin README](../../plugins/news/README.md), which shows the six designs.
