---
type: Explanation
title: The deprecated archive
description: Why superseded skills stay installable in the deprecated plugin, what each one was replaced by, and when to install it.
tags: [deprecated, archive, migration]
status: stable
---

# The deprecated archive

When a restructure replaces a skill, the old skill does not vanish. It moves into the `deprecated` plugin in the same pull request that removes it from its live plugin. Old workflows, prompts and notes that still call the old name keep working, and you can move to the replacement when it suits you.

## What the banner means

Each archived skill starts its description with "Deprecated, superseded by" and the replacement, and carries a one-line banner under its heading:

> **Deprecated.** Superseded by `workbench:pilot` [...]. This copy is archived and no longer maintained.

The skill is frozen. Nobody extends it or fixes it. Its references to its old siblings point inside `deprecated`, so the archive stays whole on its own.

## The four batches

| Batch   | Skill                         | Formerly in       | Replaced by                                                   |
| ------- | ----------------------------- | ----------------- | ------------------------------------------------------------- |
| 2026-07 | `crafting-presentations`      | `workbench`       | `presentations:creating-presentations`                        |
| 2026-07 | `perfecting-presentations`    | `workbench`       | `presentations:creating-presentations` (its perfecting phase) |
| 2026-07 | `exporting-decks-to-pptx`     | `workbench`       | `presentations:exporting-presentations-to-pptx`               |
| 2026-07 | `presentations`               | `writing`         | `presentations:designing-presentations`                       |
| 2026-08 | `autopilot`, `copilot`        | `workbench`       | `workbench:pilot`                                             |
| 2026-08 | `dispatching-parallel-agents` | `workbench`       | `workbench:subagent-driven-development`                       |
| 2026-08 | `terse-mode`                  | `workbench`       | nothing, retired                                              |
| 2026-09 | `writing`                     | `writing`         | `writing:ghostwrite` and `writing:coach`                      |
| 2026-09 | `pyramid`                     | `writing`         | `writing:ghostwrite` and `writing:coach`                      |
| 2026-09 | `tech-doc`                    | `writing`         | `writing:ghostwrite`                                          |
| 2026-10 | `frontend-design`             | `frontend-design` | `taste-skill:taste-skill`                                     |

The 2026-10 batch retired a whole plugin. The archived `frontend-design` skill is an Anthropic Apache 2.0 port, so its `LICENSE` and `NOTICE` moved into `deprecated` with it.

## When to install it

Install `deprecated` only when something you rely on still calls an old skill name. Otherwise use the replacement. Installing it beside `presentations`, `workbench` or `writing` puts two skills for the same job in front of the agent, and it may pick the frozen one.

Claude Code and Codex list the plugin; Cursor does not. For moving from `autopilot` or `copilot`, see [Move to workbench pilot](/how-to/move-to-workbench-pilot.md). The plugin's page is [deprecated](/reference/plugins/deprecated.md).
