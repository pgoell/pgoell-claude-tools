---
type: Reference
title: The news plugin
description: The three news skills, the files the newspaper keeps in a kasten vault, and the designs it renders with.
tags: [plugin, news, kasten, cron]
status: stable
---

# news

A personal daily newspaper: one self-contained HTML page per day in a kasten vault, linked from that day's daily note. Each story stays in its source language. A story an earlier edition ran comes back only as a follow-up that says what is new and links the earlier coverage.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/news/`; see the [plugin README](../../../plugins/news/README.md) for details and credits.

**Setup:** [Schedule the newspaper](/how-to/schedule-the-newspaper.md)

## Skills

Two skills set `disable-model-invocation: true`, so they run only when you type the slash command (or cron runs it): `/news:edition` and `/news:tune`. Cron starts only `/news:edition`. `/news:feedback` also starts when you give the agent feedback on the paper in plain words.

| Invocation       | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `/news:edition`  | Applies open feedback, gathers news per configured section (one subagent each where the host has them), drops repeats, writes each story in its source language, renders the page with the configured design, records what ran, and links the page from the daily note. Before rendering it rejects a story dated outside its section's `freshness_days` and fetches the lead's URL again to check its facts. Takes `--vault`, `--date` and `--periodic`; runs by hand or from cron. |
| `/news:feedback` | Turns one piece of free-text feedback ("less Polizeibericht", "more like #2026-10-07-evals-02") into config changes now, records them, and shows the config diff.                                                                                                                                                                                                                                                                                                                    |
| `/news:tune`     | An interview over sections, depth, sources, interests and design that rewrites the config, and can render today's edition in another design to compare.                                                                                                                                                                                                                                                                                                                              |

## In the vault

Everything lives under `<periodic>/05 Newspaper/`, with the periodic folder resolved as `## Arguments` in the [edition skill](../../../plugins/news/skills/edition/SKILL.md) says: `config/topics.yaml` and `config/design.yaml`, your `feedback.md` (write under `## Open`), `memory/` with every story that ran, and one `.html` page plus its `.json` data per day.

## Designs

Six designs ship, plus `plain`, the fallback when the configured design is missing. Pick one with `design:` in `config/design.yaml`, or with `/news:tune`.

| Design                  | Look                                                                |
| ----------------------- | ------------------------------------------------------------------- |
| `heimatblatt` (default) | Warm local paper; the home section framed green.                    |
| `briefing`              | One calm reading column with a sticky index.                        |
| `broadsheet`            | German print front page: Fraktur masthead, columns, hairline rules. |
| `magazine`              | Weekend supplement: full-bleed lead, big numerals.                  |
| `swiss`                 | Strict 12-column grid in Inter with one signal red.                 |
| `tabbed`                | The heimatblatt look with one tab per section.                      |

## Network

Gathering uses the host's web search and fetch tools. The scripts make two requests of their own while an edition is built: the day's forecast from Open-Meteo (free, no key; `weather: null` in `topics.yaml` turns it off) and, for a section that lists `tables:`, league tables from sportschau.de.
