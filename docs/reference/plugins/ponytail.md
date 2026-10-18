---
type: Reference
title: The ponytail plugin
description: The ponytail skills, which push the agent toward the simplest code that works, and the hooks that keep it always on.
tags: [plugin, ponytail, upstream, minimalism]
status: stable
---

# ponytail

Lazy senior dev mode: a reflex ladder that asks whether code needs to exist at all, reaches for the standard library and native platform features before dependencies, and prefers one line over fifty. Three levels: `lite`, `full` (default) and `ultra`.

**Runtimes:** Claude Code, Codex

Not in Cursor: this marketplace's Cursor manifests are generated from local plugin directories, and ponytail has none here. See [Runtimes](/reference/runtimes.md).

**Source:** upstream, not vendored: tracks [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) `main` unpinned (MIT). Versions and release cadence are the upstream author's.

**Setup:** [Set up ponytail](/how-to/set-up-ponytail.md)

## Skills

| Invocation                  | What it does                                                                                                                                                 |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `/ponytail:ponytail`        | The core mode. Applies the reflex ladder to any coding task and marks deliberate shortcuts with `ponytail:` comments that name their limit and upgrade path. |
| `/ponytail:ponytail-review` | Reviews a diff for over-engineering only: one line per finding, with what to cut and what replaces it.                                                       |
| `/ponytail:ponytail-audit`  | The same lens over a whole repo, as a ranked list of what to delete, simplify or replace. Reports; does not fix.                                             |
| `/ponytail:ponytail-debt`   | Collects every `ponytail:` comment into a debt ledger.                                                                                                       |
| `/ponytail:ponytail-gain`   | Scoreboard of ponytail's measured benchmark impact.                                                                                                          |
| `/ponytail:ponytail-help`   | Quick-reference card for the modes, skills and commands.                                                                                                     |

Ponytail ships hooks on `SessionStart`, `SubagentStart` and `UserPromptSubmit` that inject its rules into every session, so it is always on once installed.
