---
type: Reference
title: The insights plugin
description: The three insights skills, what they read, and the pages and notes they write in a kasten vault.
tags: [plugin, insights, kasten, cron, transcripts]
status: stable
---

# insights

A daily look back at your Claude Code sessions and the newspaper's runs: what went wrong more than once, why, and the change that would stop it, plus a second page on what your agents did per repository and what waits for you. Both pages land in a kasten vault and are linked from the daily note.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/insights/`; see the [plugin README](../../../plugins/insights/README.md) for details and credits.

**Setup:** [Schedule insights](/how-to/schedule-insights.md)

## Skills

All three skills set `disable-model-invocation: true`, so they run only when you type the slash command (or cron runs it): `/insights:digest`, `/insights:apply`, `/insights:activity`. Cron starts digest and activity; digest's run also carries out any review note you renamed to `## Keep`.

| Invocation           | What it does                                                                                                                                                                                                                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/insights:digest`   | Reads 14 days of transcripts through a script, groups recurring errors, guard refusals and typed corrections into problems, verifies causes where a check is cheap, and proposes one fix per problem on a page with a review note. Analyses yesterday by default, and first applies any review note you finished. Takes `--vault`, `--date` and `--periodic`. |
| `/insights:apply`    | Carries out the fixes kept in a reviewed note: a pull request per fix where a repository exists (never merged), todos in the daily note, newspaper feedback lines, and a verdict per line (applied, pending PR, already done, deferred, rejected, watch). Picks up a partly applied note where it stopped.                                                    |
| `/insights:activity` | A script counts one day per repository (pull requests, issues, failed CI, commits, issue-loop ledger lines, sessions, tokens and cost from `ccusage`, cron results, vault notes); the model picks what needs you and writes at most two sentences per repo. Links the page from the daily note with up to five lines.                                         |

## In the vault

- `<periodic>/06 Insights/`: the digest page, its data, and the review note for each day, plus `feedback.md` and `memory/`.
- `<periodic>/07 Activity/`: the activity page and its data for each day.

To decide on the digest, edit the review note: keep a line to accept its fix, delete it to reject it, start it with `no:` to reject with a reason, then rename `## Proposed` to `## Keep`. The next morning's run carries it out; `/insights:apply` does it now.
