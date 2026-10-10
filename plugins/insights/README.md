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
- `/insights:activity [--vault PATH] [--date YYYY-MM-DD]`: what your agents
  did on a day, per repository, and what waits for you now. A script counts;
  the model picks what needs you and writes at most two sentences per repo
  from PR titles and ledger lines. The date is the day counted, yesterday in
  Berlin by default.

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

## The activity page

`collect.py` counts one day and groups it by repository:

| Source                                                                       | Gives                                                                                                          |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `gh search prs --author=@me --owner=<you>`, `gh search issues --owner=<you>` | PRs opened and merged on the day, every such PR open now, issues opened and closed; your own repositories only |
| `gh run list` and `gh pr list` per active repo                               | branches whose newest finished CI run of the day failed: the default branch and those with an open PR          |
| `git log` of the default branch in each checkout under `~/Code` (`--code`)   | commits; side branches are left out, so a squash or rebase copy is not counted twice                           |
| issue-loop `ledger.tsv` files under the code root (`--ledger`)               | the day's task lines: issues, PR, minutes, notes                                                               |
| `~/.claude/projects`                                                         | sessions with a record on the day, folded into the repo their working directory belongs to, worktrees included |
| `bunx ccusage@20.0.28 claude daily --json --instances`                       | tokens and cost per project folder and in total, at list prices                                                |
| `~/.local/state/insights` and `~/.local/state/news`                          | how each cron run ended                                                                                        |
| the vault's git log                                                          | how many notes were written or changed, by top folder                                                          |

A source that fails (no `gh` login, no ledger, `ccusage` down) is marked
unavailable on the page; the run goes on. Sessions in the vault, and in every
folder under `--private` or `$INSIGHTS_PRIVATE`, are counted under `vault` and
give nothing else. The insights jobs' own sessions are left out. Cost comes
from `ccusage` alone and covers every session, the jobs' own too.

The page has three parts. **Needs you** is the only part with a link per
item: open PRs (a series is one item), CI that ended the day red, insights fixes
waiting on a PR, ledger warnings, PRs open for more than 7 days, failed cron
jobs; at most 8 items, the rest folded into groups that keep their links.
**Shipped** has one block per repo with one link to its merged PRs.
**Churn** is a table of counts with outliers marked. `render.py` refuses a
link that is not in a URL field of the collected data, and any text over its
limit.

A session is named only for an open PR under "Needs you". The transcript's
`bridge-session` record gives the `claude.ai/code/session_...` link when the
session was bridged; that link opens the remote session, which can cover
many local ones, so the page also prints `claude --resume <id>`.

The page loads nothing from outside: system fonts, no scripts.

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
07 Activity/
  2026-10-08.html          the activity page: needs you, shipped, churn
  2026-10-08.json          the counts and the model's notes it was rendered from
```

The daily note gets `Einsichten: [[01 Periodic/06 Insights/2026-10-08.html]]`
above its first heading, next to the newspaper's `Zeitung:` line. The
activity job adds `Aktivität: [[01 Periodic/07 Activity/2026-10-08.html]]`
there too, with up to five lines under it, one per linked thing that needs
you. A rerun replaces only that label line and its own link lines.

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
a logged-in `gh` for the pull requests. The activity page also needs `bunx`
for `ccusage`. To run both every morning, at 05:30 and 05:45 Europe/Berlin,
before the 06:00 newspaper, add these lines to the crontab:

```text
30 5 * * * /home/pascal/Code/pgoell-claude-tools/plugins/insights/scripts/cron-insights.sh /home/pascal/kasten-data/vault
45 5 * * * /home/pascal/Code/pgoell-claude-tools/plugins/insights/scripts/cron-activity.sh /home/pascal/kasten-data/vault
```

The first wrapper runs `claude -p "/insights:digest --vault <vault> --date <yesterday>"`
with the tools the job needs allowed, logs to
`~/.local/state/insights/<date>.log` (`INSIGHTS_LOG_DIR` changes that;
`INSIGHTS_PLUGIN_DIR` loads the plugin from a working tree to test a change),
and exits non-zero when claude fails or no page was written. Cron uses the
host's time zone; on a host not set to Europe/Berlin, add
`CRON_TZ=Europe/Berlin` above the line.
`cron-activity.sh` does the same for `/insights:activity`, allows the model
only `Read`, `Write` and `uv run`, stops after 30 minutes, and logs to
`~/.local/state/insights/<date>-activity.log`.

## Tests

`tests/run.sh` runs the activity scripts against fixture transcripts, two
ledgers, a git checkout made on the spot, and fake `gh`, `bunx` and `claude`:
no session, no network, about fifteen seconds. It covers the counts (commits
on the default branch only), the fold of a removed worktree into its repo,
the private folder, the skipped own run, torn transcript lines, the CI rule,
the ledger parsing and its repo mapping, every check `render.py` makes, the
daily note block (a rerun changes only its own lines; frontmatter, todos, the
user's bullets and a mention under a heading stay), the cron wrapper's tool
list, and a run with `gh` and `ccusage` down.

Last run, 2026-10-10: 66 of 66 checks pass.

The digest and apply skills have no test.
