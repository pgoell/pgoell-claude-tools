# Insights

Every morning, a look back at yesterday's Claude Code sessions and the
newspaper's runs: what went wrong more than once, why, and the exact change
that would stop it. One page per day in a kasten vault, linked from the daily
note beside the newspaper. A review note next to the page decides what
happens: kept fixes become pull requests, todos or newspaper feedback lines.

## Skills

- `/insights:digest [--vault PATH] [--date YYYY-MM-DD]`: reads 14 days of
  transcripts through `extract.py`, groups recurring errors, guard refusals
  and typed corrections into problems, checks memory and the files a fix would
  go to, verifies causes where a check is cheap, and writes the page, the
  review note and memory. The date is the day analysed, yesterday in Berlin by
  default. It first applies any review note you finished since the last run.
- `/insights:apply [--date YYYY-MM-DD]`: acts on a review note you finished.
  Run by hand, it takes the note as approved whether or not you renamed
  `## Proposed`. Opens a pull request per kept fix where a repository exists
  (never merges), adds todos to today's daily note, adds newspaper feedback
  lines, and records a verdict per line. A partly applied note picks up where
  it stopped.

## What it reads

`extract.py` streams `~/.claude/projects/**/*.jsonl`, main threads and
subagents, and buckets each record by its own timestamp in Europe/Berlin, not
by file date, because sessions run for days. It skips files over 300 MB and
lists them. It keeps:

- tool errors and hook failures, normalized into shapes (paths, hashes and
  numbers stripped) with daily counts over 14 days, projects, tools, the first
  word of the failing command, two examples and session ids;
- what you typed on the analysed day, main threads only, cut to 600
  characters per message;
- the newspaper's headless runs, as their own group, and its logs in
  `~/.local/state/news/`.

Sessions run in the vault give no typed text unless they touched a path under
`02 Projects/`; their errors still count. The job's own sessions are skipped.
A day's digest is about 80 KB.

## In the vault

```text
06 Insights/
  2026-10-08.html          the page: tally, one card per problem, what was seen and dropped
  2026-10-08.json          the data it was rendered from
  2026-10-08.md            the review note
  feedback.md              your feedback: write under "## Open"
  memory/problems.jsonl    one line per problem, with your verdict
  memory/applied.jsonl     every fix carried out, for the page footer
  memory/rules.md          standing rules made from your feedback
```

The daily note gets `Einsichten: [[01 Periodic/06 Insights/2026-10-08.html]]`
above its first heading, next to the newspaper's `Zeitung:` line.

## Deciding

The page cannot write anything, so you decide in the review note, from any
device:

- keep a line to accept its fix, or edit it to change the fix;
- delete a line to reject it: that problem comes back only when its hits
  triple;
- start a line with `no:` to reject it with a reason the next run reads;
- indent a bullet under a line to give that fix a note or a question
  ("done", "works as intended, no?"); an indented `no:` rejects it;
- rename `## Proposed` to `## Keep` when done.

The next morning's run carries out a note renamed `## Keep`; running
`/insights:apply` yourself carries out the note renamed or not. Either
appends a `## Done` line per item. Each item gets one verdict in memory:
`applied`, `pending` (a PR is open; it counts as applied once merged, which
the next run checks with `gh`), `already-done`, `deferred` (with what ends
the wait), `rejected` or `watch`. A line whose id matches nothing on the page
is reported, never taken as a rejection. Each card shows its problem's
verdict, and the page footer lists the fixes applied in the last 14 days and
whether each problem stopped, the PRs waiting to merge, and what is
deferred.

## Setup

Needs `uv` (the scripts are Python with inline dependencies), and `git` plus
a logged-in `gh` for the pull requests. To run it every morning at 05:30
Europe/Berlin, before the 06:00 newspaper, add this line to the crontab:

```text
30 5 * * * /home/pascal/Code/pgoell-claude-tools/plugins/insights/scripts/cron-insights.sh /home/pascal/kasten-data/vault
```

The wrapper runs `claude -p "/insights:digest --vault <vault> --date <yesterday>"`
with the tools the job needs allowed, logs to
`~/.local/state/insights/<date>.log` (`INSIGHTS_LOG_DIR` changes that;
`INSIGHTS_PLUGIN_DIR` loads the plugin from a working tree to test a change),
and exits non-zero when claude fails or no page was written. Cron uses the
host's time zone; on a host not set to Europe/Berlin, add
`CRON_TZ=Europe/Berlin` above the line.
